// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General
// Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
// implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with this program. If not, see
// <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.26;

import {AccountStorage, getAccountStorage} from "./AccountStorage.sol";

/// @title Account Storage Initializable
/// @author Alchemy
/// @notice A contract mixin that provides the functionality of OpenZeppelin's Initializable contract, using the
/// custom storage layout defined by the AccountStorage struct.
/// @dev The implementation logic here is modified from OpenZeppelin's Initializable contract from v5.0.
abstract contract AccountStorageInitializable {
    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /// @notice Modifier to put on function intended to be called only once per implementation
    /// @dev Reverts if the contract has already been initialized
    modifier initializer() {
        AccountStorage storage $ = getAccountStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$.initializing;
        uint64 initialized = $.initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $.initialized = 1;
        if (isTopLevelCall) {
            $.initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $.initializing = false;
            emit Initialized(1);
        }
    }

    /// @notice Internal function to disable calls to initialization functions
    /// @dev Reverts if the contract is currently initializing.
    function _disableInitializers() internal virtual {
        AccountStorage storage $ = getAccountStorage();
        if ($.initializing) {
            revert InvalidInitialization();
        }
        if ($.initialized != type(uint8).max) {
            $.initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}
