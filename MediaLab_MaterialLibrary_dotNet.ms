-- This is a comment  
(
local materialRoot = "V:\\INET\\MaterialLibrary"
local bitmapRoot = "V:\\INET\\MaterialLibrary\\Images"
--local materialRoot = "C:\\Users\\11697\\Desktop" -- TEMP
--local bitmapRoot = "C:\\Users\\11697\\Desktop\\Images" -- TEMP
local UVRoot = "V:\\INET\\MaterialLibrary\\UVCoordinates"
local logoPath = "T:\\logos\\CorganMediaLab_inverted.jpg"
local communicatorFile = (systemTools.getEnvVariable "TEMP")+"\\"+"MaterialLibrary_communicator.tmp"

local matLibFilenames
local categoryNames
local matLibs

local theImage = dotNetClass "System.Drawing.Image"
local fileClass = dotNetClass "System.IO.File"
	
local dnMouse dotNetClass "System.Windows.Input.Mouse"
local dnCursors dotNetClass "System.Windows.Input.Cursors"
	
local readyToDrop = false

---------------------------- Functions ----------------------------------------
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
DotNetForm.Size = (DotNetObject "Drawing.Size" 328 450)

local DotNetMenu = DotNetObject "System.Windows.Forms.MenuStrip"
local DotNetFileMenu = DotNetObject "System.Windows.Forms.ToolStripMenuItem" "File"
DotNetMenu.MdiWindowListItem = DotNetFileMenu
DotNetMenu.Items.Add(DotNetFileMenu)
	
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

------------------------------ Add components to form -------------------------------
DotNetForm.Controls.AddRange #(DotNetMenu, matCategory, chooseMaterial, DotNetPicBox, DotNetButton, DotNetButton2, dnButtonUV)

fn formLoad sender arg = (
	matCategory.DataSource = categoryNames
	matCategory.SelectedIndex = 0
	chooseMaterial.Items.AddRange(getMaterials (matCategory.SelectedIndex+1))
	chooseMaterial.SelectedIndex = 0
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
	print "mouse down!"
	sender.DoDragDrop chooseMaterial.SelectedItem ((dotnetclass "DragDropEffects").Copy)
)
fn qryContinueDrag sender arg = (
	print "query continue drag"
	
	local rect = DotNetObject "System.Drawing.Rectangle" DotNetPicBox.Location (DotNetObject "Drawing.Size" DotNetPicBox.Width DotNetPicBox.Height)
	
	(dotNetClass "System.Windows.Input.Mouse").SetCursor (dotNetClass "System.Windows.Input.Cursors").Arrow
	if (((dotNetClass "System.Windows.Forms.Control").MouseButtons != (dotNetClass "System.Windows.Forms.MouseButtons").Left) and (not (rect.Contains(DotNetForm.PointToClient((dotNetClass "System.Windows.Forms.Control").MousePosition)))) and (hitTest() != undefined)) do (
		print "drop it!"
		arg.Action = (dotNetClass "System.Windows.Forms.DragAction").Cancel
		(hitTest()).material = matLibs[matCategory.SelectedIndex+1][chooseMaterial.SelectedIndex]
	)
)

dotNet.addEventHandler DotNetForm "load" formLoad
dotNet.addEventHandler DotNetForm "closed" formClose
dotNet.addEventHandler matCategory "SelectedIndexChanged" categorySelect
dotNet.addEventHandler chooseMaterial "SelectedIndexChanged" materialSelect
dotNet.addEventHandler DotNetPicBox "MouseDown" msDown
--dotNet.addEventHandler DotNetPicBox "MouseUp" msUp
--dotNet.addEventHandler DotNetPicBox "DragLeave" dragLeave
--dotNet.addEventHandler DotNetPicBox "DragLeave" msLeave
--dotNet.addEventHandler DotNetPicBox "DragOver" dragOver
dotNet.addEventHandler DotNetPicBox "QueryContinueDrag" qryContinueDrag

dotNet.setLifeTimeControl DotNetForm #dotNet
dotNet.setLifeTimeControl DotNetMenu #dotNet
dotNet.setLifeTimeControl matCategory #dotNet
dotNet.setLifeTimeControl chooseMaterial #dotNet
dotNet.setLifeTimeControl DotNetPicBox #dotNet
dotNet.setLifeTimeControl DotNetButton #dotNet
dotNet.setLifeTimeControl DotNetButton2 #dotNet

------------------------------ Create form ------------------------------------------
loadLibraries()
DotNetForm.Show()
)