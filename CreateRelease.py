import zipfile

version = None
with open("IAmAMerchant.toc") as file:
    lines = file.readlines()
    for line in lines:
        if "## Version:" in line:
            version = line.split()[-1]
            version = f"{int(version[0:2])}.{int(version[2:4])}.{int(version[4:])}"
            break
    if version == None:
        print("[ERROR] Could not find addon version in TOC file")
        exit(1)
    for line in lines:
        if "Title:" in line:
            if version not in line:
                print("[ERROR] Addon version does not match version in title.")
                exit(0)

with zipfile.ZipFile(f"IAmAMerchant_v{version}.zip", "w") as archive:
    archive.write("Bindings.xml", "IAmAMerchant/Bindings.xml")
    archive.write("ChatThrottleLib.lua", "IAmAMerchant/ChatThrottleLib.lua")
    archive.write("IAAM_Com.lua", "IAmAMerchant/IAAM_Com.lua")
    archive.write("IAAM_Net.lua", "IAmAMerchant/IAAM_Net.lua")
    archive.write("IAAM_Core.lua", "IAmAMerchant/IAAM_Core.lua")
    archive.write("IAAM_Debug.lua", "IAmAMerchant/IAAM_Debug.lua")
    archive.write("IAAM_Diag.lua", "IAmAMerchant/IAAM_Diag.lua")
    archive.write("IAAM_Events.lua", "IAmAMerchant/IAAM_Events.lua")
    archive.write("IAAM_Link.lua", "IAmAMerchant/IAAM_Link.lua")
    archive.write("IAAM_MerchantTracker.lua", "IAmAMerchant/IAAM_MerchantTracker.lua")
    archive.write("IAAM_MerchantTracker.xml", "IAmAMerchant/IAAM_MerchantTracker.xml")
    archive.write("IAAM_Slash.lua", "IAmAMerchant/IAAM_Slash.lua")
    archive.write("IAAM_VendorWindow.lua", "IAmAMerchant/IAAM_VendorWindow.lua")
    archive.write("IAAM_VendorWindow.xml", "IAmAMerchant/IAAM_VendorWindow.xml")
    archive.write("IAmAMerchant.toc", "IAmAMerchant/IAmAMerchant.toc")
    archive.write("README.md", "IAmAMerchant/README.md")