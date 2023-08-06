IAmAMerchant Classic (v1.0.0)

Purpose:
========

    This addon allows you to display items that you want to sell to other players in an
    NPC vendor like window. Items can be added to the vendor window with a price per stack.
    The size of the stack is shown in the bottom right corner of the item icon to sell. If no
    stack size is shown, the price is per unit. Furthermore, the available amount of the item
    in your bag is shown in braces in the top left corner of the item icon.
    Any other player can inspect the items you want to sell and contact you if interested.
    This avoids the need to spam your items in the chat or to run to an auction house and
    doesn't require any fees.

Installation:
=============

    - Copy the IAmAMerchant folder to ".../World of Warcraft/_classic_/Interface/AddOns/".

Quick Guide:
============

    - Start WoW, log in and set keybindings for "Open target merchant window" and "Open your
      merchant window" functions. You can find these keybindings in the category "Addons" on
      the left. Suggested keybindings are:
        - Open target vendor window: "F6"
        - Open your vendor window: "F7"
    - Press "F7" to open your merchant window.
    - Drag and drop an item (for instance from your bag) into the merchant window.
    - A dialogue window will open. Enter the copper price per unit for your item.
      1234567 means 123 gold, 45 silver and 67 copper.
    - Press "Enter" or click on "Add Item" to add this item for sale. Press "Escape" or click
      on "Cancel" to close the dialogue without adding the item.
    - You can remove items from your list by right clicking on them. If you want to remove all
      items, you can also type "/iaam clear" into the chat.
    - When other players are targeted, the addon determines whether the targeted player uses
      IAmAMerchant and display an "Inspect Vendor" button if so. The button is grayed out if
      the player has no items to offer.
    - Press the button or use the shortcut for opening the vendor window in order to inspect
      the items offered for sale.
    - Get in contact with the player to buy items. There will be no automated buying/selling
      feature. Interaction and communication with other players is encouraged!

Bug reports:
============

    If any bugs were found, please report them with a detailed description on how to reproduce 
    the bug. Bugs can be reported on the addon's curseforge and wowinterface sites or by
    messaging me on curseforge (schnodder_iaam), wowinterface (Schnodder), or reddit (NukiWolf2).
    
    You bug report should asnwer following question:
    
        - Describe the bug: What is not working as expected?
        - Which IAmAMerchant version are you using?
        - How can the bug be reproduced?
        - Does the bug also occur if all other addons are disabled?
        - If not: Which addons are you using?
        

Release Notes:
==============

    - v2.0.0
        After years I plan to continue this addon, as I want to use it for WoW Classic Hardcore.
        - Removed nameplate feature and vendor list as this seems to be too complicated to inplement.
          Furthermore, there would be many problems with other nameplate addons.
          Instead, the addon will only check if targeted players are offering items for sale.
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