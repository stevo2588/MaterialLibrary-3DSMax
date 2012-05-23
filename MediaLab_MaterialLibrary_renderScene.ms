/*
	Corgan MediaLab Material Library v1.1
	Render Script
	Developed by Stephen Aldriedge
*/

communicatorFile = (systemTools.getEnvVariable "TEMP")+"\\"+"MaterialLibrary_communicator.tmp"

-----------------Paste Materials from File---------------------------
thecopypastedir = (systemTools.getEnvVariable "TEMP")
thecopypastefile = "materialClipboardLibrary.mat"
thecopypastestring = thecopypastedir + "\\" + thecopypastefile

pastelib = loadTempMaterialLibrary thecopypastestring
$'black slate 54x54'.material = pastelib[1]

--------------- Render ----------------
rendOutputFileName = ("V:\\INET\\MaterialLibrary\\Images\\"+pastelib[1].name+".jpg")
--rendOutputFileName = ("C:\\Users\\11697\\Desktop\\Images\\"+pastelib[1].name+".jpg") -- TEMP!
if (doesFileExist rendOutputFileName) do deleteFile rendOutputFileName
rendSaveFile = True

communicator = openFile communicatorFile mode:"w+"
format "Start" to:communicator
flush communicator; close communicator

max show vfb
max quick render

communicator = openFile communicatorFile mode:"w+"
format "Done" to:communicator
flush communicator; close communicator

quitmax #noPrompt