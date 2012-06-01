/*
	Corgan MediaLab Material Library v1.2
	Developed by Stephen Aldriedge
	
	Todo:
	-When user clicks "Add Material" check and make sure all texture maps (if any) are located in "V:\Materials2"
	-Make macro
	-Add UV option
	-Option to choose another render file besides the default
*/
(
include "MaterialLibrary_Utilities.ms"
include "MaterialLibrary_formComponents.ms"


------------------------------ Main ------------------------------------------
-- The following 4 lines are used to keep the form from going behind the main Max window
maxHandlePointer = (Windows.GetMAXHWND()) --Get the max handle pointer.
sysPointer = DotNetObject "System.IntPtr" maxHandlePointer --Convert the HWND handle of Max to a dotNet system pointer
maxHwnd = DotNetObject "MaxCustomControls.Win32HandleWrapper" sysPointer --Create a dotNet wrapper containing the maxHWND
DotNetForm.Show(maxHwnd) --Show the Max form using the wrapper.
)