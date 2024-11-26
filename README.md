# IAmAMerchant Classic (v2.3.0)

## Purpose
This addon allows you to offer items you want to sell to other players and browse the items other players want to sell by using the vendor window used by NPCs.
Items that you want to sell can be added to your vendor window with an optional price and an optional stack number.
The vendor window automatically shows the quantity of each item that was added to the vendor window including items located on the bank.
Merchants can be found by using the merchant tracker which shows all merchants in your guild or in the world that have items for sale.

## Quick Guide
- The default key bindings used are shift-ctrl-F5 to open your vendor window to edit your items for sale and shift-ctrl-F6 to open the merchant tracker.
- Open your vendor window and drag and drop an item from your bag into the vendor window.
- A dialogue window will open. Enter the copper price per unit for your item and press enter or click on "Add item".
  A price of 1234567 means 123 gold, 45 silver and 67 copper.
- You can remove items from your list by right clicking on them.
  If you want to remove all items, you can also type "/iaam clear" into the chat.
- To search for other merchants open the merchant tracker and query any merchants by clicking on the "Query World" or "Query Guild" buttons.
  This will show a list with either players near you or in your guild who have items for sale.
- Get in contact with the player to buy items.
- Type "/iaam" for a list of commands.

## Bug reports
If any bugs were found, please report them with a detailed description on how to reproduce the bug.
Bugs can be reported on the addon's curseforge and wowinterface sites or by messaging me on reddit (NukiWolf2).

Your bug report should answer following question:

    - Describe the bug: What is not working as expected?
    - Which IAmAMerchant version are you using?
    - How can the bug be reproduced?
    - Does the bug also occur if all other addons are disabled?
    - If not: Which addons are you using?

## Release Notes
- v2.3.0
  - Updated client version.
  - Fixed joining of IAmAMerchant channel.
    Channel will now only be joined when there's already another existing and visible channel.
    This shall prevent IAmAMerchant to be the first channel.
- v2.2.2
  - Improved popup for adding items.
    - Stack size can be specified.
    - The entered copper price is shown in gold, silver, and copper beneath the stack price input field.
  - Unfortunately, portraits of players might not always be shown due to technical reasons. Thus the portrait is removed in those cases.
- v2.2.1
  - Removed obsolete slash commands.
  - Fixed bug and removed unintentional chat output.
  - Replaced ReadMe.txt by README.md.
- v2.2.0
  - Replaced query surrounding functionality with query world.
    This allows to list all merchants that are online.
  - Fixed a bug that prevented other merchants to be listed in the merchant tracker when the player had to items for sale in his vendor window.
  - Removed automatic query, because of WoW Lua API functions that cannot be called from timer callbacks.
  - Removed merchant counter frame which is obsolete without the automatic query.
  - Keybindings:
    - Added default keybindings.
    - Keybindings are now listed in the "IAmAMerchant" category in the keybingind options instead of "AddOns".
  - Added the ChatThrottleLib library to improve communication and prevent possible disconnects.
- v2.1.4
  - Updated client version.
- v2.1.3
  - Disabled the bag button when the own character is targeted.
- v2.1.2
  - Added auto query feature that scans your surroundings for merchants every 30 seconds.
    If merchants were found, a small movable frame appears, showing the number of the found
    merchants. If sound is enabled (/iaam sound on), a sound is played if more merchants
    than before have been found. The auto scna is enabled by default and can be enabled or
    disabled with the check box in the merchant tracker window.
- v2.1.1
  - Minor improvements.
  - Query buttons are disabled for 10 seconds, to prevent spaming addon messages.
- v2.1.0
  - Added the "Merchant Tracker" windows which allows to search for for players near you or
    in your guild who have items for sale. Any player found will be shown in a list. The list
    item can then be clicked on to view the player's items for sale.
  - Some changes and optimizations regarding communication. Unfortunately, this will break
    compatibility with previous versions. However, since there aren't many users yet, and
    since there's no reason to not update the addon, this should be no issue.
- v2.0.0
  After years I plan to continue this addon, as I want to use it for WoW Classic Hardcore.
  - Removed nameplate feature and vendor list as this seems to be too complicated to inplement.
    Furthermore, there would be many problems with other nameplate addons.
    Instead, the addon will only check if targeted players are offering items for sale.
  - A button with a bag icon is shown when a player is targeted who has items for sale.
    This button can be moved using the square in the top left corner.
- v1.0.0
  - Brave step of going up to major version 1.0.0. The addon should be now in rather stable
    state for anyone to use. Please report any further bugs as well as how to reproduce them.
  - Fixed dropping an item into the frame when the mouse was released after starting
    the drag
  - New fix for "no player named ___ is currently playing"
  - Added security checks, that only requested item data will be processed.
  - Window can be closed with escape
  - add "/iaam sound <on/off>". If a merchant was found, a money sound is played if activated.
    This might be helpful while only few people are using this addon.
- v0.2.5
  - Implemented periodic update of the merchant frame to query item information of
    items which could not be queried on the first try
  - Added unit check to avoid sending data to not available characters resulting in
    a "no player named ___ is currently playing" warning message
- v0.2.4
  - Changed behavior of opening merchant window
  - fixed wrong display of available items
- v0.2.3
  - First official version for Classic WoW