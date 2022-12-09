//
// This source file is part of the CardinalKit open-source project
//
// SPDX-FileCopyrightText: 2022 CardinalKit and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import CardinalKit


actor TypedMockStandard<T: Hashable>: Standard {
    typealias BaseType = CustomDataSourceType<T>
    
    
    struct CustomDataSourceType<T: Hashable>: Equatable, Identifiable {
        let id: T
    }
    
    
    let dataSourceExpecations: (DataSourceElement<BaseType>) async throws -> Void
    let finishedDataSourceSequence: (any TypedAsyncSequence<DataSourceElement<BaseType>>.Type) async throws -> Void
    
    
    init(
        dataSourceExpecations: @escaping (DataSourceElement<BaseType>) async throws -> Void
            = defaultDataSourceExpecations,
        finishedDataSourceSequence: @escaping (any TypedAsyncSequence<DataSourceElement<BaseType>>.Type) async throws -> Void
            = defaultFinishedDataSourceSequence
    ) {
        self.dataSourceExpecations = dataSourceExpecations
        self.finishedDataSourceSequence = finishedDataSourceSequence
    }
    
    
    static func defaultDataSourceExpecations(
        _ element: DataSourceElement<BaseType>
    ) {
        switch element {
        case let .addition(newElement):
            print("Added \(newElement)")
        case let .removal(deletedElementId):
            print("Removed element with \(deletedElementId)")
        }
    }
    
    static func defaultFinishedDataSourceSequence(
        _ sequenceType: any TypedAsyncSequence<DataSourceElement<BaseType>>.Type
    ) {
        print("Finished: \(String(describing: sequenceType))")
    }
    
    
    func registerDataSource(_ asyncSequence: some TypedAsyncSequence<DataSourceElement<BaseType>>) {
        Task {
            do {
                for try await element in asyncSequence {
                    try await dataSourceExpecations(element)
                }
                try await finishedDataSourceSequence(type(of: asyncSequence))
            } catch {
                XCTFail("Failed data source of type \(String(describing: type(of: asyncSequence))) with \(error).")
            }
        }
    }
    
    func fulfill(expectation: XCTestExpectation) {
        expectation.fulfill()
    }
}