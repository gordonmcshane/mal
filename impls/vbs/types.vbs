Option Explicit

Dim TYPES
Set TYPES = New MalTypes

Class MalTypes
	Public LIST, VECTOR, HASHMAP, [BOOLEAN], NIL
	Public KEYWORD, [STRING], NUMBER, SYMBOL
	Public PROCEDURE

	Public [TypeName]
	Private Sub Class_Initialize
		[TypeName] = Array( _
				"LIST", "VECTOR", "HASHMAP", "BOOLEAN", _
				"NIL", "KEYWORD", "STRING", "NUMBER", _
				"SYMBOL", "PROCEDURE")

		Dim i
		For i = 0 To UBound([TypeName])
			Execute "[" + [TypeName](i) + "] = " + CStr(i)
		Next
	End Sub
End Class

Class MalType
	Public [Type]
	Public Value

	Public Function Init(lngType, varValue)
		[Type] = lngType
		Value = varValue
	End Function

    Public Function Copy()
    End Function
End Class

Function NewMalType(lngType, varValue)
	Dim varResult
	Set varResult = New MalType
	varResult.Init lngType, varValue
	Set NewMalType = varResult
End Function

Function NewMalBool(varValue)
	Set NewMalBool = NewMalType(TYPES.BOOLEAN, varValue)
End Function

Function NewMalNil()
	Set NewMalNil = NewMalType(TYPES.NIL, Null)
End Function

Function NewMalKwd(varValue)
	Set NewMalKwd = NewMalType(TYPES.KEYWORD, varValue)
End Function

Function NewMalStr(varValue)
	Set NewMalStr = NewMalType(TYPES.STRING, varValue)
End Function

Function NewMalNum(varValue)
	Set NewMalNum = NewMalType(TYPES.NUMBER, varValue)
End Function

Function NewMalSym(varValue)
	Set NewMalSym = NewMalType(TYPES.SYMBOL, varValue)
End Function

Class MalList ' Extends MalType
	Public [Type]
	Public Value
	
	Private Sub Class_Initialize
		[Type] = TYPES.LIST
		Set Value = CreateObject("System.Collections.ArrayList")
	End Sub

	Public Function Init(arrValues)
		Dim i
		For i = 0 To UBound(arrValues)
			Add arrValues(i)
		Next
	End Function

	Public Function Add(objMalType)
		Value.Add objMalType
	End Function
	
	Public Property Get Item(i)
		Set Item = Value.Item(i)
	End Property

	Public Property Let Item(i, varValue)
		Value.Item(i) = varValue
	End Property

	Public Property Set Item(i, varValue)
		Set Value.Item(i) = varValue
	End Property

	Public Function Count()
		Count = Value.Count
	End Function
End Class

Function NewMalList(arrValues)
	Dim varResult
	Set varResult = New MalList
	varResult.Init arrValues
	Set NewMalList = varResult
End Function

Class MalVector ' Extends MalType
	Public [Type]
	Public Value
	
	Private Sub Class_Initialize
		[Type] = TYPES.VECTOR
		Set Value = CreateObject("System.Collections.ArrayList")
	End Sub

	Public Function Init(arrValues)
		Dim i
		For i = 0 To UBound(arrValues)
			Add arrValues(i)
		Next
	End Function

	Public Function Add(objMalType)
		Value.Add objMalType
	End Function
	
	Public Property Get Item(i)
		Set Item = Value.Item(i)
	End Property

	Public Property Let Item(i, varValue)
		Value.Item(i) = varValue
	End Property

	Public Property Set Item(i, varValue)
		Set Value.Item(i) = varValue
	End Property

	Public Function Count()
		Count = Value.Count
	End Function
End Class

Function NewMalVec(arrValues)
	Dim varResult
	Set varResult = New MalVector
	varResult.Init arrValues
	Set NewMalVec = varResult
End Function

Class MalHashmap 'Extends MalType
	Public [Type]
	Public Value

	Private Sub Class_Initialize
		[Type] = TYPES.HASHMAP
		Set Value = CreateObject("Scripting.Dictionary")
	End Sub

	Public Function Init(arrKeys, arrValues)
		Dim i
		For i = 0 To UBound(arrKeys)
			.Add arrKeys(i), arrValues(i)
		Next
	End Function
	
	Public Function Add(varKey, varValue)
		Value.Add varKey, varValue
	End Function
	
	Public Property Get Keys()
		Keys = Value.Keys
	End Property

	Public Function Count()
		Count = Value.Count
	End Function

	Public Property Get Item(i)
		Set Item = Value.Item(i)
	End Property

	Public Property Let Item(i, varValue)
		Value.Item(i) = varValue
	End Property

	Public Property Set Item(i, varValue)
		Set Value.Item(i) = varValue
	End Property
End Class

Function NewMalMap(arrKeys, arrValues)
	Dim varResult
	Set varResult = New MalHashmap
	varResult.Init arrKeys, arrValues
	Set NewMalMap = varResult
End Function

Class VbsProcedure 'Extends MalType
	Public [Type]
	Public Value
	
	Public boolSpec
	Private Sub Class_Initialize
		[Type] = TYPES.PROCEDURE
	End Sub

	Public Function Init(objFunction, boolIsSpec)
		Set Value = objFunction
		boolSpec = boolIsSpec
	End Function

	Public Function Apply(objArgs, objEnv)
		Dim varResult
		If boolSpec Then
			Set varResult = Value(objArgs, objEnv)
		Else
			Set varResult = Value(EvaluateRest(objArgs, objEnv))
		End If
		Set Apply = varResult
	End Function
End Class

Function NewVbsProc(strFnName, boolSpec)
	Dim varResult
	Set varResult = New VbsProcedure
	varResult.Init GetRef(strFnName), boolSpec
	Set NewVbsProc = varResult
End Function

Class MalProcedure 'Extends MalType
	Public [Type]
	Public Value
	
	Private Sub Class_Initialize
		[Type] = TYPES.PROCEDURE
	End Sub

	Private objParams, objCode, objSavedEnv
	Public Function Init(objP, objC, objE)
		Set objParams = objP
		Set objCode = objC
		Set objSavedEnv = objE
	End Function

	Public Function Apply(objArgs, objEnv)
		Dim varRet
		
		Dim objNewEnv
		Set objNewEnv = NewEnv(objSavedEnv)
		Dim i
		i = 0
		Dim objList
		While i < objParams.Count
			If objParams.Item(i).Value = "&" Then
				If objParams.Count - 1 = i + 1 Then
					Set objList = NewMalList(Array())
					objNewEnv.Add objParams.Item(i + 1), objList
					While i + 1 < objArgs.Count
						objList.Add Evaluate(objArgs.Item(i + 1), objEnv)
						i = i + 1
					Wend
					i = objParams.Count ' Break While
				Else
					Err.Raise vbObjectError, _
						"MalProcedure", "Invalid parameter(s)."
				End If
			Else
				If i + 1 >= objArgs.Count Then
					Err.Raise vbObjectError, _
						"MalProcedure", "Need more arguments."
				End If
				objNewEnv.Add objParams.Item(i), _
					Evaluate(objArgs.Item(i + 1), objEnv)
				i = i + 1
			End If
		Wend
		Set varRet = Evaluate(objCode, objNewEnv)
		Set Apply = varRet
	End Function
End Class

Function NewMalProc(objParams, objCode, objEnv)
	Dim varRet
	Set varRet = New MalProcedure
	varRet.Init objParams, objCode, objEnv
	Set NewMalProc = varRet
End Function