/*
	Corgan MediaLab Material Library v1.2
	Developed by Stephen Aldriedge
	
	Todo:
	-When user clicks "Add Material" check and make sure all texture maps (if any) are located in "V:\Materials2"
	-Drag and Drop feature from image
	-Disable Assign buttons when no material is selected
	-More efficient drag and drop (change pictureBox to another control... or add callback?)
*/

/*macroScript MediaLab_MaterialLibrary
category:"MediaLab Scripts"
tooltip:"MLab Material Library"
icon:#("MediaLabButton", 1)
(*/
global materialRoot = "V:\\INET\\MaterialLibrary"
global bitmapRoot = "V:\\INET\\MaterialLibrary\\Images"
--global materialRoot = "C:\\Users\\11697\\Desktop" -- TEMP
--global bitmapRoot = "C:\\Users\\11697\\Desktop\\Images" -- TEMP
global UVRoot = "V:\\INET\\MaterialLibrary\\UVCoordinates"
global logoPath = "T:\\logos\\CorganMediaLab_inverted.jpg"
global communicatorFile = (systemTools.getEnvVariable "TEMP")+"\\"+"MaterialLibrary_communicator.tmp"

global matLibFilenames
global categoryNames
global matLibs

global selectedLibraryIndex
global selectedMaterialIndex

global theImage = dotNetClass "System.Drawing.Image" --create an Image dotNetClass
global imageWidth = 300
global imageHeight = 300

global fileClass = dotNetClass "System.IO.File"

global materialDrag = False
global materialRelease = False
global outsidePic = False

fn loadLibraries = (
	matLibFilenames = getFiles (materialRoot+"\\*.mat")
	categoryNames = for i in matLibFilenames collect (getFilenameFile i)
	matLibs = for i in matLibFilenames collect (loadTempMaterialLibrary i)
)

fn checkAndDisplayProgress = (
	print "background thread!"
	messageBox "Your material preview is currently being rendered.\nYou will be notified when it is complete." title:"Material Storage"
	
	estimatedTime = ""
	-- while loop to check file
	while estimatedTime != "Done" do (
		communicator = openFile communicatorFile mode:"rt"
		estimatedTime = readLine communicator -- read first line
		flush communicator; close communicator

		print estimatedTime
		sleep 5
	)
	-- make sure other script flushes and closes file after each write! otherwise file won't be updated
	print "Material stored successfully"
	messageBox "Your material preview is done rendering and the material has been successfully stored." title:"Material Successfully Stored"
)

-- hitTest function by MarcoBrunetta from cgsociety.org
-- Returns the object at the mouse position in the viewport
fn hitTest = (
	local theRay=mapScreenToWorldRay mouse.pos
	local dist=undefined
	local theHit=undefined
	local hitObject=undefined
	for x in objects do 
	(
		hitRay=intersectRay x theRay
		if hitRay!=undefined then (
			tempDist=distance hitRay.pos theRay.pos
			if dist==undefined or tempDist<dist then
			(
				dist=tempDist
				theHit=hitRay
				hitObject = X
			)
		)
	)
	hitObject 
)

rollout VRay_Arch "MediaLab Material Library v1.1" width:328 height:393 (
	
	dropdownlist matCategory items:(#("-- Choose Category --")+categoryNames)
	dropdownlist chooseMaterial items:#("-- Choose Material --")
	DotNetControl picBox "System.Windows.Forms.PictureBox" width:imageWidth height:imageHeight --bitmap preview
	checkButton resizeBtn "Grow" pos:[266,365]
	Button assignBtn "Assign Editor" pos:[15,365]
	Button assignSelectionBtn "Assign Selection" pos:[98,365]
	Button applyUVsBtn "Apply UVs" pos:[195,365] enabled:False
	
	on matCategory selected choice do (
		selectedLibraryIndex = choice-1
		chooseMaterial.selection = 1
		if choice != 1 then (
			chooseMaterial.items = (#("-- Choose Material --") + (for i in matLibs[choice-1] collect i.name))
			UVFile = UVRoot+"\\"+chooseMaterial.selected+".uvi"
			if (not (doesFileExist UVFile)) then (applyUVsBtn.enabled = False)
			else (applyUVsBtn.enabled = True)
		)
		else (
			chooseMaterial.items = #()
			applyUVsBtn.enabled = False
		)
		-- clean up and change image
		picBox.image.dispose()
		picBox.image = theImage.FromFile logoPath
	)

	on chooseMaterial selected choice do (
		selectedMaterialIndex = choice-1
		if choice != 1 then (
			imageToLoad = bitmapRoot+"\\"+chooseMaterial.items[choice]+".jpg"
			if (doesFileExist imageToLoad) then (picBox.image.dispose(); picBox.image = theImage.FromFile imageToLoad)
			else (picBox.image.dispose(); picBox.image = theImage.FromFile logoPath)
			
			UVFile = UVRoot+"\\"+VRay_Arch.chooseMaterial.selected+".uvi"
			if (not (doesFileExist UVFile)) then (applyUVsBtn.enabled = False)
			else (applyUVsBtn.enabled = True)
		) 
		else (
			picBox.image.dispose()
			picBox.image = theImage.FromFile logoPath
			applyUVsBtn.enabled = False
		)
	)
	
	on assignBtn pressed do (
		meditMaterials[activeMeditSlot] = matLibs[matCategory.selection-1][chooseMaterial.selection-1]
	)
	
	on assignSelectionBtn pressed do (
		if $ != undefined do ($.material = matLibs[matCategory.selection-1][chooseMaterial.selection-1])
	)
	
	on applyUVsBtn pressed do (
		UVFile = UVRoot+"\\"+VRay_Arch.chooseMaterial.selected+".uvi"
		UVInfo = openFile UVFile mode:"rt"
		
		modifString = ""
		
		do (
			currentLine = readLine UVInfo
			print currentLine
			
			if (currentLine[1] == "#") then (
				modifString = substring currentLine 2 -1
				case modifString of (
					"VRayDisplacementMod": (addModifier $ (VRayDisplacementMod()))
					"UVWMap": (addModifier $ (UVWMap()))
				)
			)
			else if (currentLine[1] == "\t") then (
				-- set modifier parameter
				parameter = filterString (substring currentLine 2 -1) ">"
				case modifString of (
					"UVWMap": (
						case parameter[1] of (
							"Type": (
								$.modifiers[1].maptype = case parameter[2] of (
									"Planar": 0
									"Cylindrical": 1
									"Spherical": 2
									"Shrink Wrap": 3
									"Box": 4
									"Face": 5
									"XYZ to UVW": 6
								)
							)
							"Length": ($.modifiers[1].length = (Execute parameter[2]))
							"Width": ($.modifiers[1].width = (Execute parameter[2]))
							"MapChan": ($.modifiers[1].mapChannel = (Execute parameter[2]))
						)
					)
					"VRayDisplacementMod": (
						case parameter[1] of (
							"Type": (
								$.modifiers[1].type = case parameter[2] of (
									"2D mapping (landscape)": 0
									"3D mapping": 1
									"Subdivision": 2
								)
							)
							"TexChan": ($.modifiers[1].texmapChannel = (Execute parameter[2]))
							"TexMap": (
								theMap = BitmapTexture()
								theMap.filename = parameter[2]
								$.modifiers[1].texmap = theMap
							)
						)
					)
				)
				
				-- if next line is another modifier or the end of file, add modifier to selection
				--currentLine = readLine UVInfo
				--if ((eof UVInfo) or (currentLine[1] == "#")) do (addModifier $ currentMod)
			)
		) while (not (eof UVInfo))
			
		flush UVInfo; close UVInfo
	)
	
	on resizeBtn changed state do (
		if state == true then (
			resizeBtn.text = "Shrink"
			VRay_Arch.width = 628
			VRay_Arch.height = 693
			picBox.width = 600
			picBox.height = 600
			resizeBtn.pos = [566,665]
			assignBtn.pos = [15,665]
			assignSelectionBtn.pos = [98,665]
			applyUVsBtn.pos = [195,665]
			matCategory.width = 600
			chooseMaterial.width = 600
		)
		else (
			resizeBtn.text = "Grow"
			VRay_Arch.width = 328
			VRay_Arch.height = 393
			picBox.width = 300
			picBox.height = 300
			resizeBtn.pos = [266,365]
			assignBtn.pos = [15,365]
			assignSelectionBtn.pos = [98,365]
			applyUVsBtn.pos = [195,365]
			matCategory.width = 300
			chooseMaterial.width = 300
		)
	)
	
	on VRay_Arch open do (
		picBox.image = theImage.FromFile logoPath
		picBox.SizeMode = picBox.SizeMode.zoom
	)
	
	on VRay_Arch close do (
		picBox.image.dispose()
		-- TODO: clean up more???
	)
)

RCmenu TopMenu (
	subMenu "File" (
		menuItem addMaterial "Add Material"
		menuItem deleteMaterial "Delete Material"
	)
	subMenu "Help" (
		menuItem helpWindow "Usage"
	)
	
	on addMaterial picked do (
		if (queryBox "You are about to add the selected material in the Material Editor to the current library. Proceed?" title:"Add Material") do (
			---------------------- add material to temp library so the other max instance can get it -------------
			thecopypastedir = (systemTools.getEnvVariable "TEMP")
			thecopypastefile = "materialClipboardLibrary.mat"
			thecopypastestring = thecopypastedir + "\\" + thecopypastefile

			pastelib = loadTempMaterialLibrary thecopypastestring -- attempt to load library
			if pastelib == undefined then (pastelib = materialLibrary meditMaterials[activeMeditSlot]) -- if library doesn't exist yet, create it
			else pastelib[1] = meditMaterials[activeMeditSlot]
			saveTempMaterialLibrary pastelib thecopypastestring
			
			------------------- add material to the correct library -------------------------------
			correctLibIndex = selectedLibraryIndex
			append matLibs[correctLibIndex] meditMaterials[activeMeditSlot]
			saveTempMaterialLibrary matLibs[correctLibIndex] matLibFilenames[correctLibIndex]
			
			----------------------- open new instance of max ------------------------------------
			startupScriptPath = (getFilenamePath (getThisScriptFilename()))+"\\MediaLab_MaterialLibrary_renderScene.ms" -- TODO: Make sure this works!
			openMaxString = "Start \"StartMax\" "+"\""+(systemTools.getEnvVariable "ADSK_3DSMAX_x64_2012")+"3dsmax.exe\" -q -silent -mip"
			maxScriptString = "-U MAXScript \""+startupScriptPath+"\""
			maxFileString = "\"V:\\INET\\_INET_Models_00_Samples\\inetMaterialRenderScene.max\""
			HiddenDOSCommand (openMaxString+" "+maxScriptString+" "+maxFileString)
			
			------------------------ create temp communication file ---------------------------
			createFile communicatorFile
			fs = openFile communicatorFile mode:"w+"
			format "unknown" to:fs
			flush fs; close fs
			
			------------ begin checking temp communicator file for when the render finishes -------------
			progressThread = dotnetobject "CSharpUtilities.SynchronizingBackgroundWorker"
			dotNet.addEventHandler progressThread "DoWork" checkAndDisplayProgress
			progressThread.RunWorkerAsync()
			
			----------------- reload libraries ----------------------
			loadLibraries()
			VRay_Arch.chooseMaterial.items = (#("-- Choose Material --") + (for i in matLibs[selectedLibraryIndex] collect i.name)) -- Refresh dropdownlist
		)

	)
	on deleteMaterial picked do (
		if (queryBox "This will delete the current material.  Are you sure you want to do this?" title:"Delete Material") do (
			VRay_Arch.picBox.image.dispose()

			fileClass.Delete (bitmapRoot+"\\"+VRay_Arch.chooseMaterial.selected+".jpg")
			
			VRay_Arch.picBox.image = theImage.FromFile logoPath
			
			deleteItem matLibs[selectedLibraryIndex] selectedMaterialIndex
			saveTempMaterialLibrary matLibs[selectedLibraryIndex] matLibFilenames[selectedLibraryIndex]
			
			loadLibraries()
			VRay_Arch.chooseMaterial.items = (#("-- Choose Material --") + (for i in matLibs[selectedLibraryIndex] collect i.name)) -- Refresh dropdownlist
			VRay_Arch.chooseMaterial.selection = 1
			-- Reload images
			imageToLoad = bitmapRoot+"\\"+VRay_Arch.chooseMaterial.selected+".jpg"
			if (doesFileExist imageToLoad) then (VRay_Arch.picBox.image.dispose(); VRay_Arch.picBox.image = theImage.FromFile imageToLoad)
			else (VRay_Arch.picBox.image.dispose(); VRay_Arch.picBox.image = theImage.FromFile logoPath)
		)
	)
	on helpWindow picked do (
		messageBox ("Top drop-down menu: Select the library you would like to choose a material from.\n\n"+
			"Bottom drop-down menu: Select the material you would like to use.\n\n"+
			"File Menu - \"Add Material\": Adds the currently select material in Max's Material Editor to the currently selected library. "+
			"This will also start another instance of Max to render a preview of the selected material.\n\n"+
			"File Menu - \"Delete Material\": Deletes the currently selected material from the material library. Also deletes the material's preview file.")\
			title:"Help"
	)
)

--loadLibraries()
--createDialog VRay_Arch menu:TopMenu

(
local DotNetForm = DotNetObject "System.Windows.Forms.Form"
DotNetForm.Size = (DotNetObject "Drawing.Size" 328 430)

local DotNetMenu = DotNetObject "System.Windows.Forms.MenuStrip"
local DotNetFileMenu = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "File"
DotNetMenu.MdiWindowListItem = DotNetFileMenu
DotNetMenu.Items.Add(DotNetFileMenu)
	
--local dnComboBox1 = DotNetObject "System.Windows.Forms.ComboBox"

/*local DotNetPicBox = DotNetObject "System.Windows.Forms.PictureBox"
DotNetPicBox.Size = (DotNetObject "Drawing.Size" 300 300)
DotNetPicBox.Location = (DotNetObject "Drawing.Point" 6 50)
DotNetPicBox.image = theImage.FromFile logoPath
DotNetPicBox.SizeMode = DotNetPicBox.SizeMode.zoom*/
	
local DotNetButton = DotNetObject "System.Windows.Forms.Button"
DotNetButton.Text = "Click Me!"
DotNetButton.Location = (DotNetObject "Drawing.Point" 15 365)
	
local DotNetButton2 = DotNetObject "System.Windows.Forms.Button"
DotNetButton2.Text = "Or Me!"
DotNetButton2.Location = (DotNetObject "Drawing.Point" 98 365)

gc()
DotNetForm.Controls.AddRange #(DotNetMenu, DotNetButton, DotNetButton2)
gc()
DotNetForm.Show()
)
--)