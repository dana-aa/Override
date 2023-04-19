// Copyright 2019, Oath Inc.
// Licensed under the terms of the MIT license. See LICENSE file in https://github.com/yahoo/Override for terms.

import Foundation
import UIKit

#if os(iOS)
extension FeaturesInteractor { /* UITableViewDelegate */

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return presenter.features[indexPath.row] is LabeledGroupItem
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter.present(tableView, groupAtIndexPath: indexPath)
    }

    /// This is a temp fix for M1+Rosetta where trailing swipe actions don't work.
    /// This puts all three actions in the leading swipe.
    /// This will stay in a fork and is not intended to be merged to the main branch.
    @available(iOS 11, *)
    open func tableView(_ tableView: UITableView,
                        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
        ) -> UISwipeActionsConfiguration? {

        guard indexPath.row <= presenter.features.count,
            let labeledFeature = presenter.features[indexPath.row] as? LabeledFeatureItemLike
            else { return UISwipeActionsConfiguration.init(actions: []) }

        let defaultAction = UIContextualAction(style: .normal,
                                        title: "Default") { [weak self] (_, _, callback: (Bool) -> Void) in
                                            self?.swipeHandler(forFeature: labeledFeature.feature,
                                                               override: .featureDefault,
                                                               tableView: tableView,
                                                               indexPath: indexPath,
                                                               completion: callback)
        }

        let enableAction = UIContextualAction(style: .normal,
                                              title: "On") { [weak self] (_, _, callback: (Bool) -> Void) in
                                                self?.swipeHandler(forFeature: labeledFeature.feature,
                                                                   override: .enabled,
                                                                   tableView: tableView,
                                                                   indexPath: indexPath,
                                                                   completion: callback)
        }

        let disableAction = UIContextualAction(style: .normal,
                                               title: "Off") { [weak self] (_, _, callback: (Bool) -> Void) in
                                                self?.swipeHandler(forFeature: labeledFeature.feature,
                                                                   override: .disabled,
                                                                   tableView: tableView,
                                                                   indexPath: indexPath,
                                                                   completion: callback)
        }
        
        defaultAction.backgroundColor = labeledFeature.feature.defaultState ? UIColor.mulah : UIColor.swedishFish
        enableAction.backgroundColor = UIColor.mulah
        disableAction.backgroundColor = UIColor.swedishFish

        var actions: [UIContextualAction]
        switch labeledFeature.feature.override {
        case .enabled:
            actions = [disableAction, defaultAction]
        case .disabled:
            actions = [enableAction, defaultAction]
        case .featureDefault:
            actions = [enableAction, disableAction]
        }
        return UISwipeActionsConfiguration(actions: actions)
    }


    @available(iOS 11, *)
    open func tableView(_ tableView: UITableView,
                        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
        ) -> UISwipeActionsConfiguration? {

        guard indexPath.row <= presenter.features.count,
            let labeledFeature = presenter.features[indexPath.row] as? LabeledFeatureItemLike
            else { return UISwipeActionsConfiguration.init(actions: []) }

        let enableAction = UIContextualAction(style: .normal,
                                              title: "On") { [weak self] (_, _, callback: (Bool) -> Void) in
                                                self?.swipeHandler(forFeature: labeledFeature.feature,
                                                                   override: .enabled,
                                                                   tableView: tableView,
                                                                   indexPath: indexPath,
                                                                   completion: callback)
        }

        let disableAction = UIContextualAction(style: .normal,
                                               title: "Off") { [weak self] (_, _, callback: (Bool) -> Void) in
                                                self?.swipeHandler(forFeature: labeledFeature.feature,
                                                                   override: .disabled,
                                                                   tableView: tableView,
                                                                   indexPath: indexPath,
                                                                   completion: callback)
        }

        enableAction.backgroundColor = UIColor.mulah
        disableAction.backgroundColor = UIColor.swedishFish

        var actions: [UIContextualAction]
        switch labeledFeature.feature.override {
        case .enabled:
            actions = [disableAction]
        case .disabled:
            actions = [enableAction]
        case .featureDefault:
            actions = [enableAction, disableAction]
        }
        return UISwipeActionsConfiguration(actions: actions)
    }

    func swipeHandler(forFeature feature: AnyFeature,
                      override: OverrideState,
                      tableView: UITableView,
                      indexPath: IndexPath,
                      completion: (Bool) -> Void) {

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        completion(true)

        presenter.showRestartPrompt(for: feature) { [weak self] resolution in
            switch resolution {
            case .acceptAndContinue:
                feature.override = override
                self?.presenter.updateFeature(tableView: tableView, indexPath: indexPath)
            case .cancel:
                return
            }
        }
    }
}

extension UISearchBar {
    var textForFeatureQuery: String? {
        if #available(iOS 13, *) {
            return searchTextField.isEditing ? text : nil
        } else {
            // Before iOS 13 the editing state was less explicit. In all versions of iOS, the search
            // text is "" even when the search bar was never tapped. It isn't ever .none()...
            return isFirstResponder ? text : nil
        }
    }
}
#endif
