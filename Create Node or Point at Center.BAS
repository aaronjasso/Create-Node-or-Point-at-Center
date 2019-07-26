Sub Main
	'==========================================
	'This macro creates a point or node at the geometrical average or
	'geometrical center of a selected group of points or nodes.
	'
	'Copyright (c) 2019 Aaron Jasso
	'
	'This program is free software: you can redistribute it and/or modify
    'it under the terms of the GNU General Public License as published by
    'the Free Software Foundation, either version 3 of the License, or
    '(at your option) any later version.
    '
    'This program is distributed in the hope that it will be useful,
    'but WITHOUT ANY WARRANTY; without even the implied warranty of
    'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    'GNU General Public License for more details.
    '
    'You should have received a copy of the GNU General Public License
    'along with this program.  If not, see <https://www.gnu.org/licenses/>.
	'
	'Written by AMJ 5.16.2019
	'
	'Please comment or contribute at https://github.com/aaronjasso/Create-Node-or-Point-at-Center
	'==========================================
    Dim App As femap.model
    Set App = feFemap()
    Dim rc As Variant

	'==========================================
    'Prompt user for input
	'==========================================
    lblGetInput:
	Begin Dialog UserDialog 410,175,"Create a Point or Node" ' %GRID:10,7,1,1
		GroupBox 10,0,290,70,"Instructions",.GroupBox1
		text 20,14,270,49,"A point or node will be created at either the geometrical center (the center of the bounding box) or the average coordinates of the input group.",.Text1
		GroupBox 10,70,90,63,"Create",.GroupBox2
		OptionGroup .create
			OptionButton 20,91,60,14,"Point",.OptionButton1
			OptionButton 20,112,60,14,"Node",.OptionButton2
		GroupBox 110,70,180,63,"Method",.GroupBox3
		OptionGroup .method
			OptionButton 120,91,150,14,"Geometric Center",.OptionButton3
			OptionButton 120,112,160,14,"Average Coordinates",.OptionButton4
		GroupBox 300,70,100,63,"Input Type",.GroupBox4
		OptionGroup .input
			OptionButton 310,91,70,14,"Points",.OptionButton5
			OptionButton 310,112,80,14,"Nodes",.OptionButton6
		OKButton 60,140,120,28
		PushButton 220,140,130,28,"Cancel",.PushButton1
		text 310,21,80,14,"Layer",.Text2
		TextBox 310,35,90,14,.layer
	End Dialog
	Dim dlg As UserDialog
	'Dialog dlg

	'condition fields
	dlg.layer = Str$(App.Info_ActiveID(FT_LAYER))

	'create dialog
	If Dialog(dlg) = 1 Then
		Exit Sub
	End If

	'validate inputs
	If Not(IsNumeric(dlg.layer)) Then
		MsgBox("You must enter a valid layer ID",vbInformation,"Invalid input")
		GoTo lblGetInput
	End If

	'check existance of chosen layer
	Dim iterLayer As femap.layer
	Set iterLayer = App.feLayer

	If iterLayer.Exist(Val(dlg.layer)) = FE_FAIL Then
		Begin Dialog UserDialog2 260,91,"Layer Not Found" ' %GRID:10,7,1,1
			text 10,14,240,28,"Layer " & dlg.layer & " does not exist. Would you like to create it?",.Text1
			OKButton 10,56,110,28
			PushButton 140,56,100,28,"Go Back",.PushButton1
		End Dialog
		Dim dlg2 As UserDialog2
		'Dialog dlg
		If Dialog(dlg2) = -1 Then
			With iterLayer
				.ID = dlg.layer
				.title = "New Layer"
			End With
			iterLayer.Put(iterLayer.ID)
		Else
			GoTo lblGetInput
		End If
	End If

	'make and fill helper vars
	Dim createPoint As Boolean
	Dim methodGeom As Boolean
	Dim inputPoint As Boolean
	Dim inputText As String

	createPoint =True
	methodGeom = True
	inputPoint = True
	inputText = "Point"

	If dlg.create = 1 Then
		createPoint = False
	End If

	If dlg.method = 1 Then
		methodGeom = False
	End If

	If dlg.input = 1 Then
		inputPoint = False
		inputText = "Node"
	End If


	'==========================================
	'Get input points or nodes
	'==========================================
	Dim inputSet As femap.Set
	Set inputSet = App.feSet

	lblGetCloud:
	If dlg.input = 0 Then
		rc = inputSet.Select(FT_POINT,True,"Select points")
	Else
		rc = inputSet.Select(FT_NODE,True,"Select nodes")
	End If

	If rc = 2 Then
		Exit Sub
	End If

	'validate selection
	If inputSet.Count = 0 Then
		MsgBox("You must select at least one " & inputText,vbInformation,"Invalid Input")
		GoTo lblGetCloud
	End If


	'==========================================
	'Calculate location of new entity
	'==========================================
	Dim newCoords(3) As Double

	If methodGeom Then
		'geometric center
		Dim Xmax, Xmin, Ymax, Ymin, Zmax, Zmin As Double
		If inputPoint Then
			'point input
			Dim iterPoint As femap.Point
			Set iterPoint = App.fePoint

			inputSet.Reset
			iterPoint.Get(inputSet.Next)
			Xmax = iterPoint.x
			Xmin = Xmax
			Ymax = iterPoint.y
			Ymin = Ymax
			Zmax = iterPoint.z
			Zmin = Zmax

			While inputSet.Next
				iterPoint.Get(inputSet.CurrentID)
				If iterPoint.x > Xmax Then
					Xmax = iterPoint.x
				ElseIf iterPoint.x < Xmin Then
					Xmin = iterPoint.x
				End If
				If iterPoint.y > Ymax Then
					Ymax = iterPoint.y
				ElseIf iterPoint.y < Ymin Then
					Ymin = iterPoint.y
				End If
				If iterPoint.z > Zmax Then
					Zmax = iterPoint.z
				ElseIf iterPoint.z < Zmin Then
					Zmin = iterPoint.z
				End If
			Wend
		Else
			'node input
			Dim iterNode As femap.Node
			Set iterNode = App.feNode

			inputSet.Reset
			iterNode.Get(inputSet.Next)
			Xmax = iterNode.x
			Xmin = Xmax
			Ymax = iterNode.y
			Ymin = Ymax
			Zmax = iterNode.z
			Zmin = Zmax

			While inputSet.Next
				iterNode.Get(inputSet.CurrentID)
				If iterNode.x > Xmax Then
					Xmax = iterNode.x
				ElseIf iterNode.x < Xmin Then
					Xmin = iterNode.x
				End If
				If iterNode.y > Ymax Then
					Ymax = iterNode.y
				ElseIf iterNode.y < Ymin Then
					Ymin = iterNode.y
				End If
				If iterNode.z > Zmax Then
					Zmax = iterNode.z
				ElseIf iterNode.z < Zmin Then
					Zmin = iterNode.z
				End If
			Wend
		End If
			newCoords(0) = (Xmax + Xmin) / 2
			newCoords(1) = (Ymax + Ymin) / 2
			newCoords(2) = (Zmax + Zmin) / 2
	Else
		'average center
		Dim xAvg As Double
		Dim yAvg As Double
		Dim zAvg As Double
		Dim i As Integer

		i = 0

		If inputPoint Then
			'point input
			Dim iterPoint2 As femap.Point
			Set iterPoint2 = App.fePoint

			inputSet.Reset
			While inputSet.Next
				iterPoint2.Get(inputSet.CurrentID)
				i = i + 1
				xAvg = (xAvg * (i-1) + iterPoint2.x) / i
				yAvg = (yAvg * (i-1) + iterPoint2.y) / i
				zAvg = (zAvg * (i-1) + iterPoint2.z) / i
			Wend
		Else
			'node input
			Dim iterNode2 As femap.Node
			Set iterNode2 = App.feNode

			inputSet.Reset
			While inputSet.Next
				iterNode2.Get(inputSet.CurrentID)
				i = i + 1
				xAvg = (xAvg * (i-1) + iterNode2.x) / i
				yAvg = (yAvg * (i-1) + iterNode2.y) / i
				zAvg = (zAvg * (i-1) + iterNode2.z) / i
			Wend
		End If
		newCoords(0) = xAvg
		newCoords(1) = yAvg
		newCoords(2) = zAvg
	End If

	'==========================================
	'Create new entity
	'==========================================

	If createPoint Then
		'create point
		Dim newPoint As femap.Point
		Set newPoint = App.fePoint
		With newPoint
			.ID = App.Info_NextID(FT_POINT)
			.layer = Val(dlg.layer)
			.xyz = newCoords
		End With
		rc = newPoint.Put(newPoint.ID)
		If rc = -1 Then
			App.feAppMessage(FCM_NORMAL,"Point " & newPoint.ID & " created")
		Else
			App.feAppMessage(FCM_ERROR,"Could not create point")
		End If
	Else
		'create node
		Dim newNode As femap.Node
		Set newNode = App.feNode
		With newNode
			.ID = App.Info_NextID(FT_NODE)
			.layer = Val(dlg.layer)
			.xyz = newCoords
		End With
		rc = newNode.Put(newNode.ID)
		If rc = -1 Then
			App.feAppMessage(FCM_NORMAL,"Node " & newNode.ID & " created")
		Else
			App.feAppMessage(FCM_ERROR,"Could not create node")
		End If
	End If


    
End Sub
