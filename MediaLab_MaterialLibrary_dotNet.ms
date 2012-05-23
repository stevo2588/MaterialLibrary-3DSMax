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

fn loadLibraries = (
	matLibFilenames = getFiles (materialRoot+"\\*.mat")
	categoryNames = for i in matLibFilenames collect (getFilenameFile i)
	matLibs = for i in matLibFilenames collect (loadTempMaterialLibrary i)
)

fn changePreview imageFile = (
	if (picBox.image != undefined) do (picBox.image.dispose())
	picBox.image = theImage.FromFile logoPath
)

fn getMaterials libIndex = (
	for i in matLibs[libIndex] collect i.name
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

local DotNetButton = DotNetObject "System.Windows.Forms.Button"
DotNetButton.Text = "Click Me!"
DotNetButton.Location = (DotNetObject "Drawing.Point" 15 385)
	
local DotNetButton2 = DotNetObject "System.Windows.Forms.Button"
DotNetButton2.Text = "Or Me!"
DotNetButton2.Location = (DotNetObject "Drawing.Point" 98 385)

------------------------------ Add components to form -------------------------------
DotNetForm.Controls.AddRange #(DotNetMenu, matCategory, chooseMaterial, DotNetPicBox, DotNetButton, DotNetButton2)

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
)

dotNet.addEventHandler DotNetForm "load" formLoad
dotNet.addEventHandler DotNetForm "closed" formClose
dotNet.addEventHandler matCategory "SelectedIndexChanged" categorySelect

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