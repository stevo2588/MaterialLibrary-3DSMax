local configFile = (getFilenamePath (getThisScriptFilename()))+"CONFIG"
local logoPath = "T:\\logos\\CorganMediaLab_inverted.jpg"
local iconPath = (getFilenamePath (getThisScriptFilename()))+"mediaLab.ico"
local communicatorFile = (systemTools.getEnvVariable "TEMP")+"\\"+"MaterialLibrary_communicator.tmp"
local materialRoot
local bitmapRoot
local UVRoot
local texMapDir
local renderFile
	
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