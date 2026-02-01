//
//  DividendDBHelper.swift
//  DividendTracker
//
//  Created by Deovil Vimal Dubey on 24/01/26.
//

import Foundation
import CoreData

class DividendDBHelper {
    static let shared = DividendDBHelper()
    
    private let context = PersistenceController.shared.container.viewContext
    private let entityName = "DividendRecord"
    
    private init() {}
    
    private func saveContext() {
        if context.hasChanges {
            try? context.save()
        }
    }
    // CREATE
    func createEntry(ticker: String, companyName: String, netDividend: Double, dataSourceType: String) {
        let record = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
        record.setValue(ticker, forKey: "ticker")
        record.setValue(Date(), forKey: "createdAt")
        record.setValue(companyName, forKey: "companyName")
        record.setValue(netDividend, forKey: "netDividend")
        record.setValue(dataSourceType, forKey: "dataSourceType")
        
        saveContext()
    }
    
    // READ
    func fetchByTickerAndSource(_ ticker: String, _ dataSourceType: String) -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(format: "ticker == %@ AND dataSourceType == %@", ticker, dataSourceType)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    func getDataFromSourceType(_ dataSourceType: String?) -> [DividendBatchResult] {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        if let type = dataSourceType {
            request.predicate = NSPredicate(format: "dataSourceType == %@", type)
        }
        let records = (try? context.fetch(request)) ?? []
        
        return records.compactMap { record in
            guard let ticker = record.value(forKey: "ticker") as? String,
                  let companyName = record.value(forKey: "companyName") as? String,
                  let netDividend = record.value(forKey: "netDividend") as? Double,
                  let dataSourceType = record.value(forKey: "dataSourceType") as? String else {
                return nil
            }
            
            return DividendBatchResult(
                ticker: ticker,
                companyName: companyName,
                netDividend: netDividend,
                dataSourceType: dataSourceType
            )
        }
    }

    //UPDATE
    func saveAll(_ results: [DividendBatchResult]) {
        for result in results {
            if let existing = fetchByTickerAndSource(result.ticker, result.dataSourceType) {
                existing.setValue(result.netDividend, forKey: "netDividend")
                existing.setValue(result.companyName, forKey: "companyName")
            } else {
                createEntry(ticker: result.ticker, companyName: result.companyName, netDividend: result.netDividend, dataSourceType: result.dataSourceType)
            }
        }
    }
    
    // DELETE
    func deleteByTickerAndSource(_ ticker: String, _ dataSourceType: String) {
        if let record = fetchByTickerAndSource(ticker, dataSourceType) {
            context.delete(record)
            saveContext()
        }
    }
}
