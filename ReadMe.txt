IAmAMerchant Classic (v1.0.0)

Purpose:
========

    This addon allows you to display items that you want to sell in a NPC merchant like
    window to other players who also has this addon (see screenshot). Other players
    who are offering at least one item will have a merchant mark on their nameplate next
    to their name, telling you that you can inspect the goods they are offering.

    If no one else has this addon installed, this addon will have no impact to the game.
    So, just download and install it for the case you find someone who is offering some
    goods!

Installation:
=============

    - Copy the IAmAMerchant folder to ".../World of Warcraft/_classic_/Interface/AddOns/".

Quick Guide:
============

    - Start WoW, log in and set keybindings for "Open target merchant window" and "Open your
      merchant window" functions. You can find these keybindings in the category "Addons" on
      the left. Suggested keybindings are:
        - Open target merchant window: "F6"
        - Open your merchant window: "F7"
    - Press "F7" to open your merchant window.
    - Drag and drop an item (for instance from your bag) into the merchant window.
    - A dialogue window will open. Enter the price per unit for your item. 1234567 means 123
      gold, 45 silver and 67 copper.
    - Press "Enter" or click on "Add Item" to add this item for sale. Press "Escape" or click
      on "Cancel" to close the dialogue without adding the item.
    - You can remove items from your list by right clicking on them. If you want to remove all
      items, you can also type "/iaam clear" into the chat.
    - Enable friendly nameplates (Shift + V) in order to see if other players are offering
      items for sale. If a players offers at least one item for sale, a little icon will
      appear next to the players name on his nameplate. Now, you can target him and press "F6"
      to query his items. A merchant window with his items will open.
    - If you don't want the icon to appear, you can type "/iaam off". Don't forget to type
      "/iaam on" again, in order to enable the nameplate icons.

Bug reports:
============

    If anz bugs are found, please report them with a detailed description on how to reproduce 
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