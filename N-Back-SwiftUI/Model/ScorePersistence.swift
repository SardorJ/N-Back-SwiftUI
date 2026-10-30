//
//  ScorePersistence.swift
//  N-Back-SwiftUI
//

import Foundation
import CoreData

/// One saved round result shown in the score history screen.
struct SavedScore: Identifiable, Equatable {
    let id: UUID
    var playerName: String
    var score: Int
    var maxScore: Int
    var date: Date
    var stimulusType: String
}

enum ScoreSortField: String, CaseIterable, Identifiable {
    case name
    case score
    case date

    var id: String { rawValue }

    var title: String {
        switch self {
        case .name: return "Name"
        case .score: return "Score"
        case .date: return "Date"
        }
    }
}

/// Core Data stack + sorted queries (lab: local database, NSSortDescriptor).
final class ScorePersistence {
    static let shared = ScorePersistence()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        let model = Self.makeManagedObjectModel()
        container = NSPersistentContainer(name: "NBackScores", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error {
                // Lab app: fail loudly during development rather than silently dropping scores.
                fatalError("Core Data failed to load: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func saveScore(playerName: String, score: Int, maxScore: Int, stimulusType: StimulusType) {
        let context = container.viewContext
        let object = NSEntityDescription.insertNewObject(forEntityName: "ScoreRecord", into: context)
        object.setValue(UUID(), forKey: "id")
        object.setValue(playerName.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "playerName")
        object.setValue(Int32(score), forKey: "score")
        object.setValue(Int32(maxScore), forKey: "maxScore")
        object.setValue(Date(), forKey: "date")
        object.setValue(stimulusType.rawValue, forKey: "stimulusType")
        persist(context)
    }

    /// Fetches scores sorted with NSSortDescriptor (lab oral-exam expectation).
    func fetchScores(sortedBy field: ScoreSortField, ascending: Bool) -> [SavedScore] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "ScoreRecord")
        let key: String
        switch field {
        case .name: key = "playerName"
        case .score: key = "score"
        case .date: key = "date"
        }
        request.sortDescriptors = [NSSortDescriptor(key: key, ascending: ascending)]

        do {
            return try viewContext.fetch(request).compactMap { object in
                guard let id = object.value(forKey: "id") as? UUID,
                      let name = object.value(forKey: "playerName") as? String,
                      let date = object.value(forKey: "date") as? Date else {
                    return nil
                }
                let score = Int(object.value(forKey: "score") as? Int32 ?? 0)
                let maxScore = Int(object.value(forKey: "maxScore") as? Int32 ?? 0)
                let stimulus = object.value(forKey: "stimulusType") as? String ?? ""
                return SavedScore(
                    id: id,
                    playerName: name,
                    score: score,
                    maxScore: maxScore,
                    date: date,
                    stimulusType: stimulus
                )
            }
        } catch {
            return []
        }
    }

    private func persist(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }

    /// Builds the Core Data model in code so we do not need a separate .xcdatamodeld file.
    private static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "ScoreRecord"
        entity.managedObjectClassName = "NSManagedObject"

        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .UUIDAttributeType
        id.isOptional = false

        let playerName = NSAttributeDescription()
        playerName.name = "playerName"
        playerName.attributeType = .stringAttributeType
        playerName.isOptional = false

        let score = NSAttributeDescription()
        score.name = "score"
        score.attributeType = .integer32AttributeType
        score.isOptional = false
        score.defaultValue = 0

        let maxScore = NSAttributeDescription()
        maxScore.name = "maxScore"
        maxScore.attributeType = .integer32AttributeType
        maxScore.isOptional = false
        maxScore.defaultValue = 0

        let date = NSAttributeDescription()
        date.name = "date"
        date.attributeType = .dateAttributeType
        date.isOptional = false

        let stimulusType = NSAttributeDescription()
        stimulusType.name = "stimulusType"
        stimulusType.attributeType = .stringAttributeType
        stimulusType.isOptional = false

        entity.properties = [id, playerName, score, maxScore, date, stimulusType]
        model.entities = [entity]
        return model
    }
}
