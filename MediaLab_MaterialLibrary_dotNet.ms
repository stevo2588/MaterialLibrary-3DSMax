 
(
local configFile = (getFilenamePath (getThisScriptFilename()))+"CONFIG"
local logoPath = "T:\\logos\\CorganMediaLab_inverted.jpg"
local communicatorFile = (systemTools.getEnvVariable "TEMP")+"\\"+"MaterialLibrary_communicator.tmp"
local materialRoot
local bitmapRoot
local UVRoot
local texMapDir
local renderFile
	
local matLibFilenames
local categoryNames
local matLibs

local theImage = dotNetClass "System.Drawing.Image"
local fileClass = dotNetClass "System.IO.File"

local dnMouse dotNetClass "System.Windows.Input.Mouse"
local dnCursors dotNetClass "System.Windows.Input.Cursors"

local readyToDrop = false

---------------------------- Functions ----------------------------------------
fn readSettings = (
	config = openFile configFile mode:"rt"
	texMapDir = (filterString (readLine config) ">")[2] -- read first line
	renderFile = (filterString (readLine config) ">")[2] -- read second line
	materialRoot = (filterString (readLine config) ">")[2] -- read third line
	bitmapRoot = materialRoot+"\\"+"Images"
	UVRoot = materialRoot+"\\"+"UVCoordinates"
	
	flush config; close config
)

fn loadLibraries = (
	matLibFilenames = getFiles (materialRoot+"\\*.mat")
	categoryNames = for i in matLibFilenames collect (getFilenameFile i)
	matLibs = for i in matLibFilenames collect (loadTempMaterialLibrary i)
)

fn getMaterials libIndex = (
	for i in matLibs[libIndex] collect i.name
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

-------------------------------- DotNet Form Components ------------------------------
local DotNetForm = DotNetObject "System.Windows.Forms.Form"
DotNetForm.Text = "Jeffrey"
DotNetForm.Size = (DotNetObject "Drawing.Size" 328 450)

local DotNetMenu = DotNetObject "System.Windows.Forms.MenuStrip"
local DotNetFileMenu = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "File"
local DotNetSettingsMenu = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "Settings"
local DotNetHelpMenu = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "Help"
local dnAddMaterial = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "Add Material"
local dnDelMaterial = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "Delete Material"
local dnConfigure = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "Configure"
local dnAbout = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "About"
DotNetMenu.MdiWindowListItem = DotNetFileMenu
DotNetFileMenu.DropDownItems.Add dnAddMaterial
DotNetFileMenu.DropDownItems.Add dnDelMaterial
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

------------------------------- Form Related Functions ------------------------------
fn changePreview imageFile = (
	if (not (doesFileExist imageFile)) do (imageFile = logoPath)
	if (DotNetPicBox.image != undefined) do (DotNetPicBox.image.dispose())
	DotNetPicBox.image = theImage.FromFile imageFile
)

------------------------------ Event Handlers ---------------------------------------
fn formLoad sender arg = (
	matCategory.DataSource = categoryNames
	matCategory.SelectedIndex = 0
	-- Appears that .net will fire the SelectedIndexChanged event for combobox on form.load, therefore
	-- having the next 2 lines will cause the menu to be twice as long
	--chooseMaterial.Items.AddRange(getMaterials (matCategory.SelectedIndex+1))
	--chooseMaterial.SelectedIndex = 0
)
fn formClose sender arg = (
	DotNetPicBox.image.dispose()
)
fn categorySelect sender arg = (
	chooseMaterial.Items.Clear()
	chooseMaterial.Items.AddRange(getMaterials (matCategory.SelectedIndex+1))
	chooseMaterial.SelectedIndex = 0
)
fn materialSelect sender arg = (
	imageToLoad = bitmapRoot+"\\"+chooseMaterial.SelectedItem+".jpg"
	changePreview imageToLoad
)
fn msDown sender arg = (
	sender.DoDragDrop chooseMaterial.SelectedItem ((dotnetclass "DragDropEffects").Copy)
)
fn qryContinueDrag sender arg = (
	local rect = DotNetObject "System.Drawing.Rectangle" DotNetPicBox.Location (DotNetObject "Drawing.Size" DotNetPicBox.Width DotNetPicBox.Height)
	
	(dotNetClass "System.Windows.Input.Mouse").SetCursor (dotNetClass "System.Windows.Input.Cursors").Cross
	if (((dotNetClass "System.Windows.Forms.Control").MouseButtons != (dotNetClass "System.Windows.Forms.MouseButtons").Left) and (not (rect.Contains(DotNetForm.PointToClient((dotNetClass "System.Windows.Forms.Control").MousePosition)))) and (hitTest() != undefined)) do (
		print "drop it!"
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
fn addMaterialClick sender arg = (
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
		startupScriptPath = (getFilenamePath (getThisScriptFilename()))+"MediaLab_MaterialLibrary_renderScene.ms" -- TODO: Make sure this works!
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

------------------------------ Add components to form -------------------------------
DotNetForm.Controls.AddRange #(DotNetMenu, matCategory, chooseMaterial, DotNetPicBox, DotNetButton, DotNetButton2, dnButtonUV)

dotNet.addEventHandler DotNetForm "load" formLoad
dotNet.addEventHandler DotNetForm "closed" formClose
dotNet.addEventHandler matCategory "SelectedIndexChanged" categorySelect
dotNet.addEventHandler chooseMaterial "SelectedIndexChanged" materialSelect
dotNet.addEventHandler DotNetPicBox "MouseDown" msDown
dotNet.addEventHandler DotNetPicBox "QueryContinueDrag" qryContinueDrag
dotNet.addEventHandler DotNetButton "Click" assignEditorClick
dotNet.addEventHandler DotNetButton2 "Click" assignSelectionClick
dotNet.addEventHandler dnAddMaterial "Click" addMaterialClick

dotNet.setLifeTimeControl DotNetForm #dotNet
dotNet.setLifeTimeControl DotNetMenu #dotNet
dotNet.setLifeTimeControl matCategory #dotNet
dotNet.setLifeTimeControl chooseMaterial #dotNet
dotNet.setLifeTimeControl DotNetPicBox #dotNet
dotNet.setLifeTimeControl DotNetButton #dotNet
dotNet.setLifeTimeControl DotNetButton2 #dotNet

------------------------------ Main ------------------------------------------
readSettings()
print materialRoot
print bitmapRoot
print UVRoot
print renderFile
print texMapDir
loadLibraries()
DotNetForm.Show()
)