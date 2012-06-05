/*
	Jeffrey - Corgan MediaLab Material Library v2.0
	Developed by Stephen Aldriedge
	
	Todo:
	-Option to choose another render file besides the default
*/
/*macroScript MediaLab_MaterialLibrary
category:"MediaLab Scripts"
tooltip:"MLab Material Library"
icon:#("MediaLabButton",1)*/
(
local assetDirectory
-- Figure out where your assets are
if (getFilenamePath (getThisScriptFilename())) == ((getDir #maxRoot)+"UI\\MacroScripts\\") then (
	assetDirectory = (getDir #maxRoot)+"Scripts\\Jeffrey_MaterialLibrary"
)
else (
	assetDirectory = trimright (getFilenamePath (getThisScriptFilename())) "\\"
)
local configFile = assetDirectory+"\\CONFIG"
local logoPath = "T:\\logos\\CorganMediaLab_inverted.jpg"
local iconPath = assetDirectory+"\\mediaLab.ico"
local enlargePath = assetDirectory+"\\enlarge.png"
local shrinkPath = assetDirectory+"\\shrink.png"
local communicatorFile = (systemTools.getEnvVariable "TEMP")+"\\MaterialLibrary_communicator.tmp"
local materialRoot
local bitmapRoot
local UVRoot
local texMapDir
local renderFile

local isEnlarged = false

local matLibFilenames
local categoryNames
local materialNames
local matLibs

local theImage = dotNetClass "System.Drawing.Image"
local fileClass = dotNetClass "System.IO.File"

local dnMouse dotNetClass "System.Windows.Input.Mouse"
local dnCursors dotNetClass "System.Windows.Input.Cursors"

local readyToDrop = false

local initializing = true

---------------------------- Functions ----------------------------------------
fn readSettings = (
	print "read settings"
	config = openFile configFile mode:"rt"
	texMapDir = (filterString (readLine config) ">")[2] -- read first line
	renderFile = (filterString (readLine config) ">")[2] -- read second line
	materialRoot = (filterString (readLine config) ">")[2] -- read third line
	bitmapRoot = materialRoot+"\\"+"Images"
	UVRoot = materialRoot+"\\"+"UVCoordinates"
	
	flush config; close config
)

fn loadLibraries = (
	print "loadLibraries"
	matLibFilenames = getFiles (materialRoot+"\\*.mat")
	if matLibFilenames.count == 0 then (
		matLibs = #()
		false
	)
	else (
		matLibs = for i in matLibFilenames collect (loadTempMaterialLibrary i)
		true
	)
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
		sleep 3
	)
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

-- Recursively get materials within a material
fn getAllSubMtls mtl = (
	allSubMtls = #()
	num = getNumSubMtls mtl
	for i=1 to num do (
		subMtl = getSubMtl mtl i
		if subMtl != undefined do (
			append allSubMtls subMtl
			join allSubMtls (getAllSubMtls subMtl)
		)
	)
	allSubMtls
)

-- Recursively get texture maps within a material
fn getAllSubTexMaps mtl_Tex = (
	allSubTexMaps = #()
	num = getNumSubTexmaps mtl_Tex
	for i=1 to num do (
		subTex = getSubTexmap mtl_Tex i
		if subTex != undefined do (
			append allSubTexMaps subTex
			join allSubTexMaps (getAllSubTexMaps subTex)
		)
	)
	allSubTexMaps
)

-- Recursively get all texture maps within all materials within a material
fn getAllTexInsideMtl mtl = (
	allTex = #()
	allMtls = join #(mtl) (getAllSubMtls mtl)
	for m in allMtls do (
		join allTex (getAllSubTexMaps m)
	)
	allTex
)

fn checkMaterialAssets mtl = (
	allTex = getAllTexInsideMtl mtl
	correctPath = true
	for t in allTex do (
		if (classOf t) == Bitmaptexture do (
			if not (matchPattern (getFilenamePath t.filename) pattern:(texMapDir+"\\*") ignoreCase:true) do (
				correctPath = false
				break
			)
		)
	)
	correctPath
)

-------------------------------- DotNet Form Components ------------------------------
local DotNetForm = DotNetObject "System.Windows.Forms.Form"
DotNetForm.Text = "Jeffrey"
DotNetForm.Size = (DotNetObject "Drawing.Size" 328 450)
DotNetForm.Icon = (DotNetObject "System.Drawing.Icon" iconPath)
--DotNetForm.TopMost = true

local DotNetMenu = DotNetObject "System.Windows.Forms.MenuStrip"
local DotNetFileMenu = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "File"
local DotNetSettingsMenu = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "Settings"
local DotNetHelpMenu = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "Help"
local dnAddMaterial = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "Add Material"
local dnDelMaterial = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "Delete Material"
local dnAddUVs = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "Add UVs"
local dnDeleteUVs = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "Delete UVs"
local dnConfigure = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "Configure"
local dnAbout = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "About"
DotNetMenu.MdiWindowListItem = DotNetFileMenu
DotNetFileMenu.DropDownItems.Add dnAddMaterial
DotNetFileMenu.DropDownItems.Add dnDelMaterial
DotNetFileMenu.DropDownItems.Add dnAddUVs
DotNetFileMenu.DropDownItems.Add dnDeleteUVs
DotNetSettingsMenu.DropDownItems.Add dnConfigure
DotNetHelpMenu.DropDownItems.Add dnAbout
DotNetMenu.Items.AddRange #(DotNetFileMenu,DotNetSettingsMenu,DotNetHelpMenu)

local matCategory = DotNetObject "System.Windows.Forms.ComboBox"
matCategory.Location = (DotNetObject "Drawing.Point" 6 28)
matCategory.DropDownWidth = 300
matCategory.Size = (DotNetObject "Drawing.Size" 300 21)
matCategory.DropDownStyle = (dotNetClass "System.Windows.Forms.ComboBoxStyle").DropDownList

local chooseMaterial = DotNetObject "System.Windows.Forms.ComboBox"
chooseMaterial.Location = (DotNetObject "Drawing.Point" 6 53)
chooseMaterial.DropDownWidth = 300
chooseMaterial.Size = (DotNetObject "Drawing.Size" 300 21)
chooseMaterial.DropDownStyle = (dotNetClass "System.Windows.Forms.ComboBoxStyle").DropDownList

local DotNetPicBox = DotNetObject "System.Windows.Forms.PictureBox"
DotNetPicBox.Size = (DotNetObject "Drawing.Size" 300 300)
DotNetPicBox.Location = (DotNetObject "Drawing.Point" 6 80)
DotNetPicBox.image = theImage.FromFile logoPath
DotNetPicBox.SizeMode = DotNetPicBox.SizeMode.zoom
DotNetPicBox.AllowDrop = true

local DotNetButton = DotNetObject "System.Windows.Forms.Button"
DotNetButton.Size = (DotNetObject "Drawing.Size" 80 22)
DotNetButton.Text = "Assign Editor"
DotNetButton.Location = (DotNetObject "Drawing.Point" 5 385)

local DotNetButton2 = DotNetObject "System.Windows.Forms.Button"
DotNetButton2.Size = (DotNetObject "Drawing.Size" 98 22)
DotNetButton2.Text = "Assign Selection"
DotNetButton2.Location = (DotNetObject "Drawing.Point" 85 385)

local dnButtonUV = DotNetObject "System.Windows.Forms.Button"
dnButtonUV.Size = (DotNetObject "Drawing.Size" 68 22)
dnButtonUV.Text = "Apply UVs"
dnButtonUV.Location = (DotNetObject "Drawing.Point" 183 385)

local dnButtonEnlarge = DotNetObject "System.Windows.Forms.Button"
dnButtonEnlarge.Size = (DotNetObject "Drawing.Size" 25 22)
--dnButtonEnlarge.Text = "Enlarge"
dnButtonEnlarge.Location = (DotNetObject "Drawing.Point" 282 385)
dnButtonEnlarge.Image = theImage.FromFile enlargePath

------------------------------- Settings Window -------------------------------------
local dnSettingsWindow = DotNetObject "System.Windows.Forms.Form"
dnSettingsWindow.Text = "Configure Settings"
dnSettingsWindow.Size = (DotNetObject "Drawing.Size" 460 160)

local dnTexMapLabel = (DotNetObject "System.Windows.Forms.Label")
dnTexMapLabel.Text = "Texture Map Path"
dnTexMapLabel.Size = (DotNetObject "Drawing.Size" 95 18)
dnTexMapLabel.Location = (DotNetObject "Drawing.Point" 5 12)

local dnTexMapBox = (DotNetObject "System.Windows.Forms.TextBox")
dnTexMapBox.Size = (DotNetObject "Drawing.Size" 275 20)
dnTexMapBox.Location = (DotNetObject "Drawing.Point" 100 10)

local dnBrowseTex = DotNetObject "System.Windows.Forms.Button"
dnBrowseTex.Text = "Browse"
dnBrowseTex.Size = (DotNetObject "Drawing.Size" 55 22)
dnBrowseTex.Location = (DotNetObject "Drawing.Point" 380 8)

local dnRenderFileLabel = (DotNetObject "System.Windows.Forms.Label")
dnRenderFileLabel.Text = "Render File"
dnRenderFileLabel.Size = (DotNetObject "Drawing.Size" 95 18)
dnRenderFileLabel.Location = (DotNetObject "Drawing.Point" 5 42)

local dnRenderFileBox = (DotNetObject "System.Windows.Forms.TextBox")
dnRenderFileBox.Size = (DotNetObject "Drawing.Size" 275 20)
dnRenderFileBox.Location = (DotNetObject "Drawing.Point" 100 40)

local dnBrowseRender = DotNetObject "System.Windows.Forms.Button"
dnBrowseRender.Text = "Browse"
dnBrowseRender.Size = (DotNetObject "Drawing.Size" 55 22)
dnBrowseRender.Location = (DotNetObject "Drawing.Point" 380 38)

local dnLibraryRepLabel = (DotNetObject "System.Windows.Forms.Label")
dnLibraryRepLabel.Text = "Library Path"
dnLibraryRepLabel.Size = (DotNetObject "Drawing.Size" 95 18)
dnLibraryRepLabel.Location = (DotNetObject "Drawing.Point" 5 72)

local dnLibraryRepBox = (DotNetObject "System.Windows.Forms.TextBox")
dnLibraryRepBox.Size = (DotNetObject "Drawing.Size" 275 20)
dnLibraryRepBox.Location = (DotNetObject "Drawing.Point" 100 70)

local dnBrowseLibrary = DotNetObject "System.Windows.Forms.Button"
dnBrowseLibrary.Text = "Browse"
dnBrowseLibrary.Size = (DotNetObject "Drawing.Size" 55 22)
dnBrowseLibrary.Location = (DotNetObject "Drawing.Point" 380 68)

local dnApplySettings = DotNetObject "System.Windows.Forms.Button"
dnApplySettings.Text = "Apply"
dnApplySettings.Size = (DotNetObject "Drawing.Size" 55 22)
dnApplySettings.Location = (DotNetObject "Drawing.Point" 100 95)

local dnCancelSettings = DotNetObject "System.Windows.Forms.Button"
dnCancelSettings.Text = "Cancel"
dnCancelSettings.Size = (DotNetObject "Drawing.Size" 55 22)
dnCancelSettings.Location = (DotNetObject "Drawing.Point" 160 95)

------------------------------- Form Related Functions ------------------------------
fn updateCategoryDropdown = (
	print "updateCategoryDropdown"
	print matLibs.count
	if (matLibFilenames != undefined) and (matLibs != undefined) and (matLibs.count > 0) then (
		categoryNames = for i in matLibFilenames collect (getFilenameFile i)
		matCategory.Items.Clear()
		matCategory.Items.AddRange(categoryNames)
		matCategory.SelectedIndex = 0
	)
	else (
		--categoryNames = #("-----------")
		matCategory.Items.Clear()
	)
	
)
fn updateMaterialDropdown = (
	print "updateMaterialDropdown"
	if (matLibs != undefined) and (matLibs.count > 0) then (
		materialNames = for i in matLibs[matCategory.SelectedIndex+1] collect i.name
		chooseMaterial.Items.Clear()
		chooseMaterial.Items.AddRange(materialNames)
		chooseMaterial.SelectedIndex = 0
	)
	else (
		--materialNames = #("-----------")
		chooseMaterial.Items.Clear()
	)
	print materialNames
)
fn changePreview imageFile = (
	if (not (doesFileExist imageFile)) do (imageFile = logoPath)
	if (DotNetPicBox.image != undefined) do (DotNetPicBox.image.dispose())
	DotNetPicBox.image = theImage.FromFile imageFile
)
fn setUVEnable = (
	print "uvenable called"
	-- enable/disable buttons accordingly
	UVFile = UVRoot+"\\"+chooseMaterial.SelectedItem+".uvi"
	if (not (doesFileExist UVFile)) or ($ == undefined) then (dnButtonUV.enabled = False)
	else (dnButtonUV.enabled = True)
)
fn setAssignEnable = (
	print "setAssignEnable"
	if $ == undefined then (DotNetButton2.enabled = False)
	else (DotNetButton2.enabled = True)
)
fn setAddUVsEnable = (
	if (selection.count != 1) or ($.modifiers.count < 1) then (dnAddUVs.enabled = False) --TODO: needs to check modifier type as well
	else (dnAddUVs.enabled = True)
)
fn setDeleteUVsEnable = (
	UVFile = UVRoot+"\\"+chooseMaterial.SelectedItem+".uvi"
	if (not (doesFileExist UVFile)) then (dnDeleteUVs.enabled = False)
	else (dnDeleteUVs.enabled = True)
)

------------------------------ Event Handlers ---------------------------------------
fn formLoad sender arg = (
	readSettings()
	-- Set text in settings window
	dnTexMapBox.Text = texMapDir
	dnRenderFileBox.Text = renderFile
	dnLibraryRepBox.Text = materialRoot
	if (loadLibraries()) then (
		updateCategoryDropdown()
		updateMaterialDropdown()
		
		print "here"
		-- load initial image
		imageToLoad = bitmapRoot+"\\"+chooseMaterial.SelectedItem+".jpg"
		changePreview imageToLoad
		
		setUVEnable()
		setAssignEnable()
		setAddUVsEnable()
		setDeleteUVsEnable()
	)
	else ( -- disable controls if no libraries were loaded
		DotNetButton.Enabled = false
		DotNetButton2.Enabled = false
		dnButtonUV.Enabled = false
		DotNetPicBox.Enabled = false
		DotNetFileMenu.Enabled = false
	)
	initializing = false
)
fn formShown sender arg = (
	print "shown!"
)
fn formClose sender arg = (
	DotNetPicBox.image.dispose()
	dnButtonEnlarge.Image.dispose()
	callbacks.removeScripts id:#mlmlSelection
)
fn categorySelect sender arg = (
	if not initializing do (
		print "categorySelect"
		updateMaterialDropdown()
		imageToLoad = bitmapRoot+"\\"+chooseMaterial.SelectedItem+".jpg"
		changePreview imageToLoad
		setUVEnable()
		setDeleteUVsEnable()
	)
)
fn materialSelect sender arg = (
	if not initializing do (
		print "materialSelect"
		imageToLoad = bitmapRoot+"\\"+chooseMaterial.SelectedItem+".jpg"
		changePreview imageToLoad
		setUVEnable()
		setDeleteUVsEnable()
	)
)
fn msDown sender arg = (
	sender.DoDragDrop chooseMaterial.SelectedItem ((dotnetclass "DragDropEffects").Copy)
)
fn qryContinueDrag sender arg = (
	local rect = DotNetObject "System.Drawing.Rectangle" DotNetPicBox.Location (DotNetObject "Drawing.Size" DotNetPicBox.Width DotNetPicBox.Height)
	
	(dotNetClass "System.Windows.Input.Mouse").SetCursor (dotNetClass "System.Windows.Input.Cursors").Cross
	if (((dotNetClass "System.Windows.Forms.Control").MouseButtons != (dotNetClass "System.Windows.Forms.MouseButtons").Left) and (not (rect.Contains(DotNetForm.PointToClient((dotNetClass "System.Windows.Forms.Control").MousePosition)))) and (hitTest() != undefined)) do (
		arg.Action = (dotNetClass "System.Windows.Forms.DragAction").Cancel
		(hitTest()).material = matLibs[matCategory.SelectedIndex+1][chooseMaterial.SelectedIndex+1]
	)
)
fn assignEditorClick sender arg = (
	meditMaterials[activeMeditSlot] = matLibs[matCategory.SelectedIndex+1][chooseMaterial.SelectedIndex+1]
)
fn assignSelectionClick sender arg = (
	if $ != undefined do ($.material = matLibs[matCategory.SelectedIndex+1][chooseMaterial.SelectedIndex+1])
)
fn applyUVsClick sender arg = (
	UVFile = UVRoot+"\\"+chooseMaterial.SelectedItem+".uvi"
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
		)
	) while (not (eof UVInfo))
		
	flush UVInfo; close UVInfo
)
fn enlargeClick sender arg = (
	dnButtonEnlarge.Image.dispose()
	if isEnlarged then (
		isEnlarged = false
		dnButtonEnlarge.Image = theImage.FromFile enlargePath
		
		DotNetForm.Size = (DotNetObject "Drawing.Size" 328 450)
		
		matCategory.Width = 300
		matCategory.DropDownWidth = 300

		chooseMaterial.Width = 300
		chooseMaterial.DropDownWidth = 300

		DotNetPicBox.Size = (DotNetObject "Drawing.Size" 300 300)

		DotNetButton.Location = (DotNetObject "Drawing.Point" 5 385)

		DotNetButton2.Location = (DotNetObject "Drawing.Point" 85 385)

		dnButtonUV.Location = (DotNetObject "Drawing.Point" 183 385)

		dnButtonEnlarge.Location = (DotNetObject "Drawing.Point" 282 385)
	)
	else (
		isEnlarged = true
		dnButtonEnlarge.Image = theImage.FromFile shrinkPath

		DotNetForm.Size = (DotNetObject "Drawing.Size" 628 750)
		
		matCategory.Width = 600
		matCategory.DropDownWidth = 600

		chooseMaterial.Width = 600
		chooseMaterial.DropDownWidth = 600

		DotNetPicBox.Size = (DotNetObject "Drawing.Size" 600 600)

		DotNetButton.Location = (DotNetObject "Drawing.Point" 5 685)

		DotNetButton2.Location = (DotNetObject "Drawing.Point" 85 685)

		dnButtonUV.Location = (DotNetObject "Drawing.Point" 183 685)

		dnButtonEnlarge.Location = (DotNetObject "Drawing.Point" 582 685)
	)
)
fn addMaterialClick sender arg = (
	if (queryBox "You are about to add the selected material in the Material Editor to the current library. Proceed?" title:"Add Material") do (
		correctAssets = checkMaterialAssets meditMaterials[activeMeditSlot]
		
		if correctAssets or (queryBox ("This material contains assets not located in "+texMapDir+". Are you sure you want to add it to the library?") title:"Add Material") do (
			---------------------- add material to temp library so the other max instance can get it -------------
			thecopypastedir = (systemTools.getEnvVariable "TEMP")
			thecopypastefile = "materialClipboardLibrary.mat"
			thecopypastestring = thecopypastedir + "\\" + thecopypastefile
			
			pastelib = loadTempMaterialLibrary thecopypastestring -- attempt to load library
			if pastelib == undefined then (pastelib = materialLibrary meditMaterials[activeMeditSlot]) -- if library doesn't exist yet, create it
			else pastelib[1] = meditMaterials[activeMeditSlot]
			saveTempMaterialLibrary pastelib thecopypastestring
			
			------------------- add material to the correct library -------------------------------
			append matLibs[matCategory.SelectedIndex+1] meditMaterials[activeMeditSlot]
			saveTempMaterialLibrary matLibs[matCategory.SelectedIndex+1] matLibFilenames[matCategory.SelectedIndex+1]
			
			----------------------- open new instance of max ------------------------------------
			startupScriptPath = assetDirectory+"\\MediaLab_MaterialLibrary_renderScene.ms"
			openMaxString = "Start \"StartMax\" "+"\""+(getDir #maxRoot)+"3dsmax.exe\" -q -silent -mip"
			maxScriptString = "-U MAXScript \""+startupScriptPath+"\""
			HiddenDOSCommand (openMaxString+" "+maxScriptString+" "+"\""+renderFile+"\"")
			
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
			--categorySelect undefined undefined -- reload chooseMaterial dropdown
			updateMaterialDropdown()
		)
	)
)
fn deleteMaterialClick sender arg = (
	if (queryBox "This will delete the current material.  Are you sure you want to do this?" title:"Delete Material") do (
		changePreview logoPath

		fileClass.Delete (bitmapRoot+"\\"+chooseMaterial.SelectedItem+".jpg")
		
		deleteItem matLibs[matCategory.SelectedIndex+1] (chooseMaterial.SelectedIndex+1)
		saveTempMaterialLibrary matLibs[matCategory.SelectedIndex+1] matLibFilenames[matCategory.SelectedIndex+1]
		
		loadLibraries()
		categorySelect undefined undefined -- reload chooseMaterial dropdown
		
		-- Reload images
		imageToLoad = bitmapRoot+"\\"+chooseMaterial.SelectedItem+".jpg"
		changePreview imageToLoad
	)
)
fn addUVsClick sender arg = (
	if (selection.count == 1) and ($.modifiers.count > 0) do (
		UVFile = UVRoot+"\\"+chooseMaterial.SelectedItem+".uvi"
		UVInfo = openFile UVFile mode:"w+"
		
		for m in $.modifiers do (
			print (m as string)
			case (classOf m) of (
				Uvwmap: (
					format "#UVWMap\n" to:UVInfo
					format "\tType>" to:UVInfo
					mtype = case m.maptype of (
						0: "Planar"
						1: "Cylindrical"
						2: "Spherical"
						3: "Shrink Wrap"
						4: "Box"
						5: "Face"
						6: "XYZ to UVW"
					)
					format (mtype+"\n") to:UVInfo
					format ("\tLength>"+(m.length as string)+"\n") to:UVInfo
					format ("\tWidth>"+(m.width as string)+"\n") to:UVInfo
					format ("\tMapChan>"+(m.mapChannel as string)+"\n") to:UVInfo
				)
				VRayDisplacementMod: (
					format "#VRayDisplacementMod\n" to:UVInfo
					format "\tType>" to:UVInfo
					mtype = case m.type of (
						0: "2D mapping (landscape)"
						1: "3D mapping"
						2: "Subdivision"
					)
					format (mtype+"\n") to:UVInfo
					format ("\tTexChan>"+(m.texmapChannel as string)+"\n") to:UVInfo
					if m.texmap != undefined do (
						format ("\tTexMap>"+(m.texmap.filename as string)+"\n") to:UVInfo
					)
				)
			)
		)
		
		flush UVInfo; close UVInfo
		setDeleteUVsEnable()
		setUVEnable()
	)
)
fn deleteUVsClick sender arg = (
	UVFile = UVRoot+"\\"+chooseMaterial.SelectedItem+".uvi"
	deleteFile UVFile
	setUVEnable()
	setDeleteUVsEnable()
)
fn aboutClick sender arg = (
	(dotNetClass "System.Windows.Forms.MessageBox").Show("\"Jeffrey\", the Material Library\n\n \xa9 2012 Corgan MediaLab")
)
fn configClick sender arg = (
	dnSettingsWindow.ShowDialog DotNetForm
)
fn browseTexClick sender arg = (
	dnFolderBrowse = DotNetObject "System.Windows.Forms.FolderBrowserDialog"
	dnFolderBrowse.Description = "Choose texture maps folder"
	result = dnFolderBrowse.ShowDialog()
	if result == result.OK do (
		dnTexMapBox.Text = dnFolderBrowse.SelectedPath
		print dnTexMapBox.Text
	)
)
fn browseRenderClick sender arg = (
	dnFileBrowse = DotNetObject "System.Windows.Forms.OpenFileDialog"
	dnFileBrowse.Title = "Choose Render file"
	dnFileBrowse.DefaultExt = "max"
	dnFileBrowse.Filter = "max files (*.max)|*.max";
	result = dnFileBrowse.ShowDialog()
	if result == result.OK do (
		dnRenderFileBox.Text = dnFileBrowse.FileName
		print dnRenderFileBox.Text
	)
)
fn browseLibraryClick sender arg = (
	dnFolderBrowse = DotNetObject "System.Windows.Forms.FolderBrowserDialog"
	dnFolderBrowse.Description = "Choose Library folder"
	result = dnFolderBrowse.ShowDialog()
	if result == result.OK do (
		dnLibraryRepBox.Text = dnFolderBrowse.SelectedPath
		print dnLibraryRepBox.Text
	)
)
fn applySettingsClick sender arg = (
	createFile configFile
	fs = openFile configFile mode:"w+"
	format ("TextureMapDir>"+dnTexMapBox.Text+"\n") to:fs
	format ("MaterialRenderFile>"+dnRenderFileBox.Text+"\n") to:fs
	format ("MaterialLibraryRepos>"+dnLibraryRepBox.Text) to:fs
	flush fs; close fs
	
	readSettings()
	if (loadLibraries()) then (
		updateCategoryDropdown()
		updateMaterialDropdown()
		
		print "here"
		-- load initial image
		imageToLoad = bitmapRoot+"\\"+chooseMaterial.SelectedItem+".jpg"
		changePreview imageToLoad
		
		DotNetButton.Enabled = true
		DotNetPicBox.Enabled = true
		DotNetFileMenu.Enabled = true
		setUVEnable()
		setAssignEnable()
		setAddUVsEnable()
		setDeleteUVsEnable()
	)
	else ( -- disable controls if no libraries were loaded
		changePreview logoPath
		updateCategoryDropdown()
		updateMaterialDropdown()
		DotNetButton.Enabled = false
		DotNetButton2.Enabled = false
		dnButtonUV.Enabled = false
		DotNetPicBox.Enabled = false
		DotNetFileMenu.Enabled = false
	)
	dnSettingsWindow.Close()
)
fn cancelSettingsClick sender arg = (
	dnSettingsWindow.DialogResult == dnSettingsWindow.DialogResult.Cancel
	
	dnSettingsWindow.Close()
)
fn settingsClosing sender arg = (
	if dnSettingsWindow.DialogResult == dnSettingsWindow.DialogResult.Cancel then (
		dnTexMapBox.Text = texMapDir
		dnRenderFileBox.Text = renderFile
		dnLibraryRepBox.Text = materialRoot
	)
)
/*fn onPaintForm sender arg = (
	print "hello"
	(DotNetClass "System.Windows.Forms.ControlPaint").DrawBorder arg.Graphics DotNetForm.ClientRectangle (DotNetClass "System.Drawing.Color").DarkBlue (DotNetClass "System.Windows.Forms.ButtonBorderStyle").Solid	
)
fn onResizeForm sender arg = (
	DotNetForm.Invalidate()
)*/
-- this function must be global so it can be registered as a callback
global selectionChanged
fn selectionChanged = (
	setAssignEnable()
	setUVEnable()
	setAddUVsEnable()
)

------------------------------ Add components to forms -------------------------------
DotNetForm.Controls.AddRange #(DotNetMenu, matCategory, chooseMaterial, DotNetPicBox, DotNetButton, DotNetButton2, dnButtonUV, dnButtonEnlarge)
dnSettingsWindow.Controls.AddRange #(dnTexMapLabel, dnTexMapBox, dnBrowseTex, dnRenderFileLabel, dnRenderFileBox, dnBrowseRender, dnLibraryRepLabel, dnLibraryRepBox, dnBrowseLibrary, dnApplySettings, dnCancelSettings)

---------------------------- Register event handler functions -----------------------
dotNet.addEventHandler DotNetForm "load" formLoad
dotNet.addEventHandler DotNetForm "Shown" formShown
dotNet.addEventHandler DotNetForm "closed" formClose
--dotNet.addEventHandler DotNetForm "Paint" onPaintForm
--dotNet.addEventHandler DotNetForm "Resize" onResizeForm
dotNet.addEventHandler matCategory "SelectedIndexChanged" categorySelect
dotNet.addEventHandler chooseMaterial "SelectedIndexChanged" materialSelect
dotNet.addEventHandler DotNetPicBox "MouseDown" msDown
dotNet.addEventHandler DotNetPicBox "QueryContinueDrag" qryContinueDrag
dotNet.addEventHandler DotNetButton "Click" assignEditorClick
dotNet.addEventHandler DotNetButton2 "Click" assignSelectionClick
dotNet.addEventHandler dnButtonEnlarge "Click" enlargeClick
dotNet.addEventHandler dnAddMaterial "Click" addMaterialClick
dotNet.addEventHandler dnDelMaterial "Click" deleteMaterialClick
dotNet.addEventHandler dnAddUVs "Click" addUVsClick
dotNet.addEventHandler dnDeleteUVs "Click" deleteUVsClick
dotNet.addEventHandler dnConfigure "Click" configClick
dotNet.addEventHandler dnAbout "Click" aboutClick
dotNet.addEventHandler dnButtonUV "Click" applyUVsClick

dotNet.addEventHandler dnApplySettings "Click" applySettingsClick
dotNet.addEventHandler dnCancelSettings "Click" cancelSettingsClick
dotNet.addEventHandler dnSettingsWindow "FormClosing" settingsClosing
dotNet.addEventHandler dnBrowseTex "Click" browseTexClick
dotNet.addEventHandler dnBrowseRender "Click" browseRenderClick
dotNet.addEventHandler dnBrowseLibrary "Click" browseLibraryClick

callbacks.removeScripts id:#mlmlSelection
-- make sure the callback function is global!
callbacks.addScript #selectionSetChanged "selectionChanged()" id:#mlmlSelection

dotNet.setLifeTimeControl DotNetForm #dotNet
dotNet.setLifeTimeControl DotNetMenu #dotNet
dotNet.setLifeTimeControl matCategory #dotNet
dotNet.setLifeTimeControl chooseMaterial #dotNet
dotNet.setLifeTimeControl DotNetPicBox #dotNet
dotNet.setLifeTimeControl DotNetButton #dotNet
dotNet.setLifeTimeControl DotNetButton2 #dotNet

------------------------------ Main ------------------------------------------
-- The following 4 lines are used to keep the form from going behind the main Max window
maxHandlePointer = (Windows.GetMAXHWND()) --Get the max handle pointer.
sysPointer = DotNetObject "System.IntPtr" maxHandlePointer --Convert the HWND handle of Max to a dotNet system pointer
maxHwnd = DotNetObject "MaxCustomControls.Win32HandleWrapper" sysPointer --Create a dotNet wrapper containing the maxHWND
DotNetForm.Show(maxHwnd) --Show the Max form using the wrapper.
)