#uses "CtrlXml"
#uses "tools/modules/csv.reader"
#uses "tools/modules/xml.panels.tools"
#uses "tools/modules/knp.generator.constants"
#uses "tools/modules/popup.tools"

const int StepYToNextTableGroup = 120;
const int XMLWidth = 1850;
const int NodeIdOfSizeXML = 8;
const int StartPositionX = 20; 
const int StartPositionY = 70;
const int BorderWidthForSikn = 1000;
const string RefFileNamePressure = "objects/TOSymbolsGroup/tnKNP_luP_max.xml";
const string RefFileNameMinMaxPressure = "objects/TOSymbolsGroup/tnKNP_luP_minMax.xml";
const string RefFileNameAlarm = "objects/TOSymbolsGroup/tnKNP_luBool2H.xml";
const string SysNameSMT = "TNZSSMT:";

float CountOfZdvOnEachKp = 0;
dyn_float countRowInKP;
int PosYUnderFirstTable = maxINT();
dyn_mixed BackColorShapeSizeForNps;
int currentYvoltage, currentYesu;
int beginTableInLU, endTableInLU;

mapping ParamsForXML = makeMapping(
		"Name", makeDynMixed("ru_RU.utf8", "", "en_US.utf8", ""),
		"Size", XMLWidth + " ",
		"BackColor", "{192,192,192}",
		"RefPoint", "0 0",
		"RefFileName", "RefFileName",
		"Type", "tnKNP_Panel",
		"DPI", "96"
);

void KnpGenerator_GenerateAll(dyn_string csvFiles, string saveFolder, string delimiter)
{
	int i;
	try
	{
		for (i = 1; i <= dynlen(csvFiles); i++)
			KnpGenerator_Generate(csvFiles[i], saveFolder, delimiter);
	}
	catch
	{
		PopupTools_StandardWarningBoxOkCancel("Не удалось создать файл из " + csvFiles[i]);
	}
	finally
	{
		PopupTools_StandardInfoBox("Создано файлов: " + (i - 1));
	}
}

void KnpGenerator_Generate(string csvFile, string saveFolder, string delimiter)
{
	int currentX, currentY, xmlHeight;
	dyn_dyn_string dataForCreating, dataFromCSV;
	string nameOfNps, nameOfLu, nameOfSikn, dollarParameterSystemName;
	dynClear(BackColorShapeSizeForNps);
	currentX = StartPositionX; currentY = StartPositionY;	
	dataFromCSV = CsvReader_ReadFile(csvFile, delimiter);
	mapping listIdForXML = XmlPanelTools_CreateXmlPanel(ParamsForXML);	
	for (int i = 1; i <= dynlen(dataFromCSV); i++)
	{
		dynAppend(dataForCreating, dataFromCSV[i]);
		if (i + 1 > dynlen(dataFromCSV) || dataFromCSV[i + 1][1] != "")
		{	
			switch (dataForCreating[1][1])
			{
				case "NPS":
				{
					nameOfNps = dataForCreating[1][2];
					dollarParameterSystemName = dataForCreating[1][3];
					KnpGenerator_GenerateNps(listIdForXML, dataForCreating, nameOfNps, 
							 				 dollarParameterSystemName, currentX, currentY);
					currentY += StepYToNextTableGroup;
				}
				break;
				case "LU":
				{
					nameOfLu = dataForCreating[1][2];
					dollarParameterSystemName = dataForCreating[1][3];
					dynRemove(dataForCreating,2);
					KnpGenerator_GenerateLu(listIdForXML, dataForCreating, nameOfLu, 
							 				dollarParameterSystemName, currentX, currentY);
					currentY += StepYToNextTableGroup;
				}
				break;
				case "SIKN":
				{
					nameOfSikn = dataForCreating[1][2];
					dollarParameterSystemName = dataForCreating[1][3];
					dynRemove(dataForCreating,2);
					KnpGenerator_GenerateSikn(listIdForXML, dataForCreating, nameOfSikn, 
							 				  dollarParameterSystemName, currentX, currentY);
					currentY += StepYToNextTableGroup;
				}
				break;
			}
			dynClear(dataForCreating);
		}
	}
	xmlHeight = currentY;
	xmlAppendChild(listIdForXML["rootNodeDocument"], NodeIdOfSizeXML, XML_TEXT_NODE, xmlHeight);
	string csvFileName = baseName(csvFile);
	csvFileName = delExt(csvFileName);
	string saveFilePath = saveFolder + csvFileName + ".xml";
	xmlDocumentToFile(listIdForXML["rootNodeDocument"], saveFilePath);

	KnpGenerator_SetBorderSizeForNps(saveFilePath);
}

void KnpGenerator_SetBorderSizeForNps(string filePath)
{
	file savedXmlFile;
	dyn_string linesOfFile;
	string shapeSizeProp, stringFromFile;
	int currentShapeSizePos, lineFilePosition;
	fileToString(filePath, stringFromFile);
	linesOfFile = strsplit(stringFromFile, "\n");
	currentShapeSizePos = 1; lineFilePosition = 1;
	while(lineFilePosition <= dynlen(linesOfFile))
	{
		if (strpos(linesOfFile[lineFilePosition], "RECTANGLENPS") > -1) 
		{	
			while (strpos(linesOfFile[lineFilePosition], "Size") < 0)
			{
				lineFilePosition++;
			}
			shapeSizeProp = "    <prop name=\"Size\">" + 
							BackColorShapeSizeForNps[currentShapeSizePos] + " " + 
							BackColorShapeSizeForNps[currentShapeSizePos + 1] + "</prop>";
			currentShapeSizePos += 2;	
			strreplace(linesOfFile[lineFilePosition], linesOfFile[lineFilePosition], shapeSizeProp);
		}
		lineFilePosition++;
	}
	savedXmlFile = fopen(filePath, "w");
	for (int i = 1; i <= dynlen(linesOfFile); i++)
	{
		fputs(linesOfFile[i], savedXmlFile);
		fputs("\n", savedXmlFile);
	}
	fclose(savedXmlFile);
	dynClear(BackColorShapeSizeForNps);
}

void KnpGenerator_GenerateNps(mapping &listId, dyn_dyn_string dataForCreating, string nameOfNps,
							  string dollarParameterSystemName, int &currentX, int &currentY)
{
	dyn_dyn_string creatingTable;
	int startX, startY, maxCurrentY, width, height, i;
	startX = currentX; startY = currentY; maxCurrentY = currentY; width = 0; height = 0; i = 2;
	KnpGenerator_CreateBorderForNps(listId, dataForCreating, startX, startY, width, height);
	while (i < dynlen(dataForCreating))
	{
		dynAppend(creatingTable, dataForCreating[i]);
		if (dataForCreating[i + 1][2] != "")
		{
			KnpGenerator_CreateTableForNps(listId, creatingTable, dollarParameterSystemName,
										   currentX, currentY);
			dynClear(creatingTable);
			width = KnpGenerator_Max(width, currentX);
			maxCurrentY = KnpGenerator_Max(maxCurrentY, currentY);
			currentY = startY;
		}
		i++;
	}
	dynAppend(creatingTable, dataForCreating[i]);
	if (creatingTable[1][2] == "ESU")
	{
		currentX = startX; currentY = PosYUnderFirstTable + 32;
	}
	KnpGenerator_CreateTableForNps(listId, creatingTable, dollarParameterSystemName,
								   currentX, currentY);
	currentX = startX;
	maxCurrentY = KnpGenerator_Max(maxCurrentY, currentY);
  	height = (maxCurrentY - startY) + 30;
	currentY = maxCurrentY;
	width += 185;
	PosYUnderFirstTable = maxINT();
	dynAppend(BackColorShapeSizeForNps,width); dynAppend(BackColorShapeSizeForNps,height);
}

void KnpGenerator_GenerateLu(mapping &listId, dyn_dyn_string dataForCreating, string nameOfLu,
							 string dollarParameterSystemName, int &currentX, int &currentY)
{
	int startX = currentX;
	KnpGenerator_CreateBorderAndHeaderToLu(listId, dataForCreating, nameOfLu, currentX, currentY);	
	currentY += 46;	
	dynRemove(dataForCreating, 1);
	KnpGenerator_CreateRowsToLu(listId, dataForCreating, dollarParameterSystemName, currentX, 
								currentY);
	currentX = startX;
}

void KnpGenerator_CreateTableForNps(mapping &listId, dyn_dyn_string dataForCreating,
									string dollarParameterSystemName, int &currentX, int &currentY)
{
	switch (dataForCreating[1][2])
	{
		case "P":
			KnpGenerator_CreatePressureTableForNps(listId, dataForCreating, 
												   dollarParameterSystemName, currentX, currentY);
			break;
		case "FGU":
			KnpGenerator_CreateFguTableForNps(listId, dataForCreating, dollarParameterSystemName,
										  	  currentX, currentY);
			break;
		case "Other":
			KnpGenerator_CreateTableWithOtherValuesForNps(listId, dataForCreating, 
													  	  dollarParameterSystemName,currentX,
													  	  currentY);
			break;
		case "ESU":
			KnpGenerator_CreateEsuTableForNps(listId, dataForCreating, dollarParameterSystemName,
										  	  currentX, currentY);
			break;
		default:
			KnpGenerator_CreateStandardTableForNps(listId, dataForCreating,
												   dollarParameterSystemName, currentX, currentY);
			break;
	}
}

void KnpGenerator_CreateStandardTableForNps(mapping &listId, dyn_dyn_string dataForCreating, 
											string dollarParameterSystemName, int &currentX,
											int &currentY)
{
	string mappingKey, refFileNameForHeadTable, refFileNameForRowTable, 
		   dollarParameterKpressure, panelReferenceName;
	dollarParameterKpressure = "1";
	mappingKey = dataForCreating[1][2];
	if (mappingHasKey(KnpGeneratorConstants_FileNamesForTableHeader, mappingKey))
	{
		refFileNameForHeadTable = KnpGeneratorConstants_FileNamesForTableHeader[mappingKey];
		refFileNameForRowTable = KnpGeneratorConstants_FileNamesForTableRow[mappingKey];
	}
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	XmlPanelTools_AddSymbol(listId, refFileNameForHeadTable, panelReferenceName, "", "", currentX,
							currentY);
	currentY += 46;
	KnpGenerator_AddRowsToTableForNps(listId, dataForCreating,refFileNameForRowTable, 
									  dollarParameterKpressure, dollarParameterSystemName, 
									  currentX, currentY);
	currentX += 220;
}

void KnpGenerator_AddRowsToTableForNps(mapping &listId, dyn_dyn_string dataForCreating, 
									   string refFileNameForRowTable,
									   string dollarParameterKpressure,
									   string dollarParameterSystemName, 
									   int &currentX, int &currentY)
{
	dyn_mixed dollars;
	string panelReferenceName;
	for (int i = 2; i <= dynlen(dataForCreating); i++)
	{
		panelReferenceName = "PANEL_REF" + listId["referenceId"];
		dollars = makeDynMixed("$DPE", dataForCreating[i][4],
							   "$kPressure", dollarParameterKpressure,
							   "$systemName", dollarParameterSystemName,
							   "$titleText", "\"" + dataForCreating[i][3] + "\"");
		XmlPanelTools_AddSymbol(listId, refFileNameForRowTable, panelReferenceName, "", dollars,
								currentX, currentY);
		currentY += 24;
	}	
}

void KnpGenerator_CreateTableWithOtherValuesForNps(mapping &listId, dyn_dyn_string dataForCreating, 
												   string dollarParameterSystemName, int currentX, 
												   int &currentY)
{
	uint currentReferenceNode, refShapeSerial;
	string mappingKey, refFileNameForHeadTable, panelReferenceName,
		   transformValueString, langText;
	mappingKey = dataForCreating[1][2];
	if (mappingHasKey(KnpGeneratorConstants_FileNamesForTableHeader, mappingKey))
		refFileNameForHeadTable = KnpGeneratorConstants_FileNamesForTableHeader[mappingKey];
	langText = "Норм.";
	refShapeSerial = 7;
	transformValueString = "1 0 0 1 0 0";
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	currentReferenceNode = XmlPanelTools_AddSymbol(listId, refFileNameForHeadTable, 
						   panelReferenceName, "", "", currentX, currentY);
	KnpGenerator_CreateLangTextForTable(listId, langText, transformValueString, refShapeSerial,
										currentReferenceNode);
	for (int i = 2; i <= dynlen(dataForCreating); i++)
	{
		currentY += 23;
		KnpGenerator_AddRowToOtherValuesTable(listId, dataForCreating[i], dollarParameterSystemName,
											  currentX, currentY);
	}
}

void KnpGenerator_AddRowToOtherValuesTable(mapping &listId, dyn_string dataForCreating, 
										   string dollarParameterSystemName, int currentX, 
										   int &currentY)
{
	dyn_mixed dollars;
	string refFileNameForRowTable, panelReferenceName;
	if (patternMatch("_tnKNP_tn_*.Ctrl.CountAvr?NA", dataForCreating[4]))
	{
		panelReferenceName = "PANEL_REF" + listId["referenceId"];
		refFileNameForRowTable = "objects/TOSymbolsGroup/tnKNP_nsTechMin.xml";
		dollars = makeDynMixed("$DPE", dataForCreating[4],
							   "$kPressure", 1,
							   "$systemName", dollarParameterSystemName,
							   "$titleText", "\"" + dataForCreating[3] + "\"");
		XmlPanelTools_AddSymbol(listId, refFileNameForRowTable, panelReferenceName, "", dollars,
								currentX, currentY);
	}
	else
	{
		panelReferenceName = "PANEL_REF" + listId["referenceId"];
		refFileNameForRowTable = "objects_parts/TOSymbols/tnKNP_tableTitle.xml";
		dollars = makeDynMixed("$titleText", "\"" + dataForCreating[3] + "\"");
		XmlPanelTools_AddSymbol(listId, refFileNameForRowTable, panelReferenceName, "", dollars,
								currentX, currentY);
		panelReferenceName = "PANEL_REF" + listId["referenceId"];
		refFileNameForRowTable = "objects_parts/TOSymbols/tnKNP_tableBool.xml"; 
		dollars = makeDynMixed("$DPE", dataForCreating[4],
							   "$systemName", dollarParameterSystemName);
		XmlPanelTools_AddSymbol(listId, refFileNameForRowTable, panelReferenceName, "", dollars,
								currentX + 73, currentY);	
	}
}

void KnpGenerator_AddShapeWithPrimitiveTextProperty(uint rootNode, uint nodeId, uint refShapeSerial)
{
	xmlSetElementAttribute(rootNode, nodeId, "layerId", 0);
	xmlSetElementAttribute(rootNode, nodeId, "RefShapeSerial", refShapeSerial);
	xmlSetElementAttribute(rootNode, nodeId, "shapeType", "RefShape");
	xmlSetElementAttribute(rootNode, nodeId, "GroupPath", "");
}

void KnpGenerator_AddShapeWithPrimitiveTextPropertyForPrimitives(uint rootNode, uint nodeId, uint refShapeSerial)
{
	xmlSetElementAttribute(rootNode, nodeId, "layerId", 0);
	xmlSetElementAttribute(rootNode, nodeId, "RefShapeSerial", refShapeSerial);
	xmlSetElementAttribute(rootNode, nodeId, "shapeType", "RefShape");
	xmlSetElementAttribute(rootNode, nodeId, "GroupPath", "0");
}

void KnpGenerator_CreateLangTextForTable(mapping &listId, string dataForCreating = "",
										 string transformValue, uint refShapeSerial,
										 uint referenceNode)
{
	dyn_mixed primitiveTextProps;
	uint rootNode, shapeNode, propertiesNode, propNode;
	rootNode = listId["rootNodeDocument"];
	primitiveTextProps = XmlPanelTools_MakeLangStringDynMixed(dataForCreating);
	shapeNode = xmlAppendChild(rootNode, referenceNode, XML_ELEMENT_NODE, "shape");
	KnpGenerator_AddShapeWithPrimitiveTextProperty(rootNode, shapeNode, refShapeSerial);
	propertiesNode = xmlAppendChild(rootNode, shapeNode, XML_ELEMENT_NODE, "properties");
	propNode = xmlAppendChild(rootNode, propertiesNode, XML_ELEMENT_NODE, "prop");
			   xmlSetElementAttribute(rootNode, propNode, "name", "primitiveText");
			   xmlSetElementAttribute(rootNode, propNode, "type", "LANG_TEXT_ARRAY");
	XmlPanelTools_AddPropsToShape(rootNode, propNode, primitiveTextProps);
	propNode = xmlAppendChild(rootNode, propertiesNode, XML_ELEMENT_NODE, "prop");
			   xmlSetElementAttribute(rootNode, propNode, "name", "transform");
			   xmlSetElementAttribute(rootNode, propNode, "type", "TRANSFORM");
			   xmlAppendChild(rootNode, propNode, XML_TEXT_NODE, transformValue);
}

void KnpGenerator_CreateEsuTableForNps(mapping &listId, dyn_dyn_string dataForCreating,
									   string dollarParameterSystemName,
									   int &currentX, int &currentY)
{
	dyn_mixed dollars;
	string panelReferenceName, refFileNameForRowTable;
	KnpGenerator_AddHeadTableForEsu(listId, currentX, currentY);
	currentY += 46;
	for (int i = 2; i <= dynlen(dataForCreating); i++)
	{
		//ищем имя ЕСУ
		string descriptionESU = WinCC_GetDescription(dollarParameterSystemName, dataForCreating[i][4]);
		dyn_string splitPointDescr = strsplit(descriptionESU, ".");
		string nameESU = splitPointDescr[2];
		// рисуем первый и второй стоблцы
		panelReferenceName = "PANEL_REF" + listId["referenceId"];
		refFileNameForRowTable = "objects_parts/TOSymbols/tnKNP_tableTitle.xml";
		dollars = makeDynMixed("$titleText", nameESU); 
		XmlPanelTools_AddSymbol(listId, refFileNameForRowTable, panelReferenceName, "", dollars, 
								currentX, currentY);
		panelReferenceName = "PANEL_REF" + listId["referenceId"];
		refFileNameForRowTable = KnpGeneratorConstants_FileNamesForTableRow["ESU"];
		dollars = makeDynMixed("$DPE", dataForCreating[i][4],
							   "$kPressure", 1,
					   		   "$systemName", dollarParameterSystemName);
		XmlPanelTools_AddSymbol(listId, refFileNameForRowTable, panelReferenceName, "", dollars, 
								currentX + 73, currentY);
		currentY += 23;
	}
}

void KnpGenerator_CreatePressureTableForNps(mapping &listId, dyn_dyn_string dataForCreating,
									   		string dollarParameterSystemName, int &currentX, 
									   		int &currentY)
{
	int currentPosX, currentPosY;
	currentPosX = currentX; currentPosY = currentY;
	KnpGenerator_AddHeadForPressureTableForNps(listId, currentX, currentY);
	currentPosY += 45;
	for (int i = 2; i <= dynlen(dataForCreating); i++)
	{	
		KnpGenerator_AddRowForPressureTableForNps(listId, dataForCreating, dollarParameterSystemName,
												  i, currentPosX, currentPosY);
		currentPosY += 24;
	}	
	PosYUnderFirstTable = currentPosY;
	currentY = currentPosY;
	currentX += 405;
}

void KnpGenerator_AddHeadForPressureTableForNps(mapping &listId, int currentX, int currentY)
{
	string panelReferenceName, fileName;
	mapping props = makeMapping(
				"RefPoint", currentX + " " + currentY,
				"ForeColor", "yellow",
				"BackColor", "{159,159,159}",
				"Location", currentX + " " + currentY,
				"Size", 74 + " " + 47,
				"serialId", 0,
				"TabOrder", 0);	
	XmlPanelTools_AddShape(listId, "RECTANGLEPRESSURE", "RECTANGLE", props);
	currentX += 73; 
	fileName = "objects/TOSymbolsStatic/tnKNP_luHeaderZdvP_1.xml";
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	XmlPanelTools_AddSymbol(listId, fileName, panelReferenceName, "", "", currentX, currentY);
	currentX += 126;
	fileName = "objects/TOSymbolsStatic/tnKNP_luHeaderZdvP_2.xml";
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	XmlPanelTools_AddSymbol(listId, fileName, panelReferenceName, "", "", currentX, currentY);
}

void KnpGenerator_AddRowForPressureTableForNps(mapping &listId, dyn_dyn_string dataForCreating,
									   		   string dollarParameterSystemName, int index,
									   		   int currentX, int currentY)
{
	dyn_mixed dollars;
	string panelReferenceName, fileName;
	fileName = "objects_parts/TOSymbols/tnKNP_tableTitle.xml";
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	dollars = makeDynMixed("$titleText", "\"" + dataForCreating[index][3] + "\"");
	XmlPanelTools_AddSymbol(listId, fileName, panelReferenceName, "", dollars, currentX, currentY);	
	currentX += 73;
	fileName = "objects/TOSymbolsGroup/tnKNP_luP_max.xml";
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	dollars = makeDynMixed("$DPE", dataForCreating[index][4],
						   "$kPressure", 1,
						   "$systemName", dollarParameterSystemName);
	XmlPanelTools_AddSymbol(listId, fileName, panelReferenceName, "", dollars, currentX, currentY);	
	currentX += 126;
	fileName = "objects/TOSymbolsGroup/tnKNP_luP_minMax.xml";
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	dollars = makeDynMixed("$DPE", dataForCreating[index][4],
						   "$kPressure", 1,
						   "$systemName", dollarParameterSystemName);
	XmlPanelTools_AddSymbol(listId, fileName, panelReferenceName, "", dollars, currentX, currentY);	
}

void KnpGenerator_CreateFguTableForNps(mapping &listId, dyn_dyn_string dataForCreating,
									   string dollarParameterSystemName, int &currentX, 
									   int &currentY)
{
	dyn_mixed dollars;
	uint currentReferenceNode, refShapeSerial;
	string panelReferenceName, refFileName, langText, transformValueString;
	mapping props = makeMapping(
				"RefPoint", currentX + " " + currentY,
				"ForeColor", "yellow",
				"BackColor", "{159,159,159}",
				"Location", currentX + " " + currentY,
				"Size", 74 + " " + 47,
				"serialId", 0,
				"TabOrder", 0);	
	refShapeSerial = 3;
	langText = "Давление";
	transformValueString = "1 0 0 1 0 0";
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	refFileName = "objects/TOSymbolsStatic/tnKNP_nsHeaderP.xml";
	currentReferenceNode = XmlPanelTools_AddSymbol(listId, refFileName, panelReferenceName, "", "", 
												   currentX, currentY);
	KnpGenerator_CreateLangTextForTable(listId, langText, transformValueString, refShapeSerial,
										currentReferenceNode);
	currentY += 45;
	for (int i = 2; i <= dynlen(dataForCreating); i++)
	{
		panelReferenceName = "PANEL_REF" + listId["referenceId"];
		refFileName = "objects_parts/TOSymbols/tnKNP_tableTitle.xml";
		dollars = makeDynMixed("$titleText", "\"" + dataForCreating[i][3] + "\"");
		XmlPanelTools_AddSymbol(listId, refFileName, panelReferenceName, "", dollars, currentX, 
								currentY);	
		refFileName = "objects/TOSymbolsGroup/tnKNP_nsP_minMaxSdku.xml";
		panelReferenceName = "PANEL_REF" + listId["referenceId"];
		dollars = makeDynMixed("$DPE", dataForCreating[i][4],
							   "$kPressure", 1,
							   "$systemName", dollarParameterSystemName);
		XmlPanelTools_AddSymbol(listId, refFileName, panelReferenceName, "", dollars, currentX + 73, 
								currentY);
		currentY += 23;
	}	
	currentX += 283;
}

void KnpGenerator_AddHeadTableForEsu(mapping &listId, int currentX, int currentY)
{
	uint rootNode, currentReferenceNode, refShapeSerial;
	string transformValueString, langText, refFileName, panelReferenceName;
	refShapeSerial = 3;
	langText = "ЕСУ";
	transformValueString = "1 0 0 1 15 1.25";
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	refFileName = "objects/TOSymbolsStatic/tnKNP_nsHeaderP.xml";
	currentReferenceNode = XmlPanelTools_AddSymbol(listId, refFileName, panelReferenceName, "", "", 
												   currentX, currentY);
	KnpGenerator_CreateLangTextForTable(listId, langText, transformValueString, refShapeSerial,
										currentReferenceNode);	
}

void KnpGenerator_AddShapeWithTransformProperty(uint rootNode, uint referenceNode,
										uint refShapeSerial, string transformValue, bool thisRowAlarmOrVoltage = false)
{
	uint shapeNode, propertiesNode, propNode;
	shapeNode = xmlAppendChild(rootNode, referenceNode, XML_ELEMENT_NODE, "shape");
	if(thisRowAlarmOrVoltage)
		KnpGenerator_AddShapeWithPrimitiveTextPropertyForPrimitives(rootNode, shapeNode, refShapeSerial);
	else
		KnpGenerator_AddShapeWithPrimitiveTextProperty(rootNode, shapeNode, refShapeSerial);
	propertiesNode = xmlAppendChild(rootNode, shapeNode, XML_ELEMENT_NODE, "properties");
	propNode = xmlAppendChild(rootNode, propertiesNode, XML_ELEMENT_NODE, "prop");
			   xmlSetElementAttribute(rootNode, propNode, "name", "transform");
		 	   xmlSetElementAttribute(rootNode, propNode, "type", "TRANSFORM");
		 	   xmlAppendChild(rootNode, propNode, XML_TEXT_NODE, transformValue);
}

void KnpGenerator_AddTransformingCellToHeadTable(mapping &listId, string refFileNameForHeadTable,
												 string tableName, string componentOfHeadTable, 
												 dyn_mixed dollars, float coefficientX, 
												 float coefficientY, int currentX, int currentY)
{
	dyn_float geometry;
	string panelReferenceName;
	int currentPosX, currentPosY;
	uint rootNode, currentReferenceNode;
	dyn_string transformValueToDynString;
	dyn_dyn_float transformValueToDynFloat;
	rootNode = listId["rootNodeDocument"];
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	currentPosX = KnpGeneratorConstants_ValuesForTableComponents[tableName][componentOfHeadTable]
																["Location"][1];
	currentPosY = KnpGeneratorConstants_ValuesForTableComponents[tableName][componentOfHeadTable]
																["Location"][2];									  
	geometry = KnpGeneratorConstants_ValuesForTableComponents[tableName][componentOfHeadTable]
															 ["Geometry"];
	geometry[3] += currentX; geometry[4] += currentY;
	currentReferenceNode = XmlPanelTools_AddSymbol(listId, refFileNameForHeadTable, 
												   panelReferenceName, geometry, dollars,
												   currentPosX, currentPosY);
	transformValueToDynFloat[1] = KnpGeneratorConstants_ValuesForTableComponents[tableName]
														 [componentOfHeadTable]["Transform1"];
	transformValueToDynFloat[2] = KnpGeneratorConstants_ValuesForTableComponents[tableName]
														 [componentOfHeadTable]["Transform2"];
	if (coefficientX != 0) 
		transformValueToDynFloat[1][3] -= currentX * coefficientX;
	if (coefficientY != 0)
		transformValueToDynFloat[1][4] += currentY / coefficientY;
	transformValueToDynString[1] = KnpGenerator_FloatGeometryToString(transformValueToDynFloat[1]);
	transformValueToDynString[2] = KnpGenerator_FloatGeometryToString(transformValueToDynFloat[2]);
	KnpGenerator_AddShapeWithTransformProperty(rootNode, currentReferenceNode, 1, 
											   transformValueToDynString[1]);
	KnpGenerator_AddShapeWithTransformProperty(rootNode, currentReferenceNode, 2, 
											   transformValueToDynString[2]);	
}

string KnpGenerator_FloatGeometryToString(dyn_float geometryValues)
{
	dynInsertAt(geometryValues, 0, 2); 
	dynInsertAt(geometryValues, 0, 2);
	string result = strjoin(geometryValues, " ");
	return result;
}

void KnpGenerator_CreateBorderForNps(mapping &listId, dyn_dyn_string nameOfNps, int currentX, 
									 int currentY, int width, int height)
{
	string tableName;
	float coefficientX;
	tableName = "НПС"; 
	coefficientX = 0.0627449;
	currentX -= 10; currentY -= 10;
	KnpGenerator_AddCaptionOverBorder(listId, tableName, nameOfNps[1][2], coefficientX, currentX,currentY);
	KnpGenerator_AddControlButtonsForNps(listId, nameOfNps[1], currentX + (width + 1525), currentY - 29);
	mapping props = makeMapping("RefPoint", currentX + " " + currentY,
								"ForeColor", "yellow",
								"BackColor", "_Transparent",
								"Location", currentX + " " + currentY,
								"Size", width + " " + height,
								"serialId", 0,
								"TabOrder", 0);
	XmlPanelTools_AddShape(listId, "RECTANGLENPS", "RECTANGLE", props);
}

int KnpGenerator_Max(int value1, int value2)
{
	if (value1 > value2)
		return value1;
	else
		return value2;
}

int KnpGenerator_Min(int value1, int value2)
{
	if (value1 < value2)
		return value1;
	else
		return value2;
}

void KnpGenerator_AddStandardHeadLu(mapping &listId, int currentX, int currentY)
{
	uint rootNode, currentReferenceNode, refShapeSerial;
	string panelReferenceName, refFileName, transformValue;
	refShapeSerial = 112;
	rootNode = listId["rootNodeDocument"];
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	refFileName = "objects/TOSymbolsStatic/tnKNP_luHeader3.xml";
	transformValue = "0.9821428571428561 0 0 1 14.53571428571512 0";
	currentReferenceNode = XmlPanelTools_AddSymbol(listId, refFileName, panelReferenceName, "", "", 
												   currentX, currentY);	
	KnpGenerator_AddShapeWithTransformProperty(rootNode, currentReferenceNode, refShapeSerial, 
											   transformValue);
}

void KnpGenerator_AddAlarmUToHeadLu(mapping &listId, int &currentX, int currentY)
{
	dyn_mixed dollars;
	float coefficientX, coefficientY;
	string refFileNameForHeadTable, tableName, componentOfHeadTable;
	coefficientX = 1.304; coefficientY = 0;
	dollars = makeDynMixed("$ZDV", "Напряжение");
	tableName = "ЛУ"; componentOfHeadTable = "Напряжение";
	refFileNameForHeadTable = "objects/TOSymbolsStatic/tnKNP_capZDV.xml";
	KnpGenerator_AddTransformingCellToHeadTable(listId, refFileNameForHeadTable,  tableName, 
									   			componentOfHeadTable, dollars, coefficientX, 
									   			coefficientY, currentX, currentY);	
	currentX += 107;
}

void KnpGenerator_AddEsuToHeadLu(mapping &listId, int currentX, int currentY)
{
	uint rootNode, currentReferenceNode, refShapeSerial;
	string transformValueString, langText, refFileName, panelReferenceName;
	refShapeSerial = 106;
	langText = "ЕСУ";
	transformValueString = "1 0 0 1 23 1.25";
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	refFileName = "objects/TOSymbolsStatic/tnKNP_luHeaderU_2.xml";
	currentReferenceNode = XmlPanelTools_AddSymbol(listId, refFileName, panelReferenceName, "", "", 
												   currentX, currentY);
	KnpGenerator_CreateLangTextForTable(listId, langText, transformValueString, refShapeSerial,
										currentReferenceNode);	
}

void KnpGenerator_AddZdv(mapping &listId, string zdvNum, int currentX, int currentY)
{
	uint rootNode;
	dyn_mixed dollars;
	string panelReferenceName, refFileNameForHeadTable;
	rootNode = listId["rootNodeDocument"];
	dollars = makeDynMixed("$ZDV", zdvNum);
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	refFileNameForHeadTable = "objects/TOSymbolsStatic/tnKNP_capZDV.xml";
	XmlPanelTools_AddSymbol(listId, refFileNameForHeadTable, panelReferenceName, "", dollars,
							currentX, currentY);	
}

void KnpGenerator_AddTransformShapeToKpsod(mapping &listId, uint referenceNode,                    
										   dyn_float transformValue,int refShapeSerial)
{
	string transformValueString;
	uint rootNode, shapeNode, propertiesNode, propNode;
	rootNode = listId["rootNodeDocument"];
	transformValueString = KnpGenerator_FloatGeometryToString(transformValue);
	shapeNode = xmlAppendChild(rootNode, referenceNode, XML_ELEMENT_NODE, "shape");
		 		xmlSetElementAttribute(rootNode, shapeNode, "layerId", 0);
				xmlSetElementAttribute(rootNode, shapeNode, "RefShapeSerial", refShapeSerial);
		 		xmlSetElementAttribute(rootNode, shapeNode, "shapeType", "RefShape");
				xmlSetElementAttribute(rootNode, shapeNode, "GroupPath", "");
	propertiesNode = xmlAppendChild(rootNode, shapeNode, XML_ELEMENT_NODE, "properties");
	propNode = xmlAppendChild(rootNode, propertiesNode, XML_ELEMENT_NODE, "prop");
		 	   xmlSetElementAttribute(rootNode, propNode, "name", "transform");
		 	   xmlSetElementAttribute(rootNode, propNode, "type", "TRANSFORM");
		 	   xmlAppendChild(rootNode, propNode, XML_TEXT_NODE, transformValueString);	
}

void KnpGenerator_AddKpsod(mapping &listId, string dpe, string kpsodName,
					 	   string dollarParameterSystemName, int currentX, int &currentY)
{	
	dyn_mixed dollars;
	dyn_float geometry;
	uint currentReferenceNode;
	dyn_dyn_float transformValueToDynFloat;
	int refShapeSerial, currentPosX, currentPosY;
	string groupPath, refFileName, panelReferenceName, titleText;
	titleText = "Камера приема СОД";
	refFileName = "objects_parts/TOSymbols/tnKNP_tableTitle.xml";
	panelReferenceName = "PANEL_REF" + listId["referenceId"];								  
	geometry = KnpGeneratorConstants_ValuesForTableComponents["ЛУ"]["КПСОД"]["Geometry"];
	currentPosX = KnpGeneratorConstants_ValuesForTableComponents["ЛУ"]["КПСОД"]["Location"][1];
	currentPosY = KnpGeneratorConstants_ValuesForTableComponents["ЛУ"]["КПСОД"]["Location"][2];	
	geometry[3] += currentX; geometry[4] += currentY;
	if (kpsodName != "")
		titleText = kpsodName;
	dollars = makeDynMixed("$titleText", "\"" + titleText + "\"");
	currentReferenceNode = XmlPanelTools_AddSymbol(listId, refFileName, panelReferenceName,         
												   geometry, dollars, currentPosX, currentPosY);
	for (int i = 1; i <= 2; i++)
	{
		transformValueToDynFloat[i] = KnpGeneratorConstants_ValuesForTableComponents["ЛУ"]["КПСОД"]
																				  ["Transform" + i];
		refShapeSerial = KnpGeneratorConstants_ValuesForTableComponents["ЛУ"]["КПСОД"]
																	   ["RefShapeSerial" + i];
		if (i == 1)
			transformValueToDynFloat[i][3] -= 2.3595 * currentX;
		KnpGenerator_AddTransformShapeToKpsod(listId, currentReferenceNode,
											  transformValueToDynFloat[i], refShapeSerial);
	}
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	refFileName = "objects/TOSymbolsGroup/tnKNP_luP_max.xml";
	dollars = makeDynMixed("$DPE", dpe,
						   "$kPressure", "$kPressure",
						   "$systemName", dollarParameterSystemName);
	currentX += 245;
	XmlPanelTools_AddSymbol(listId, refFileName, panelReferenceName, "", dollars, currentX, 
							currentY);
	if (patternMatch("*_LU_*_KIP_*", dpe))
	{
		panelReferenceName = "PANEL_REF" + listId["referenceId"];
		refFileName = "objects/TOSymbolsGroup/tnKNP_luP_minMax.xml";
		currentX += 126;
		XmlPanelTools_AddSymbol(listId, refFileName, panelReferenceName, "", dollars, currentX, 
								currentY);	
	}
}	

void KnpGenerator_AddZdvStateToRowLu(mapping &listId, string dpe,
					 	   			 string dollarParameterSystemName, int currentX, int currentY)
{
	uint rootNode;
	dyn_mixed dollars;
	string panelReferenceName, refFileNameForRowTable;
	rootNode = listId["rootNodeDocument"];
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	refFileNameForRowTable = "objects/TOSymbolsGroup/tnKNP_luInt2H.xml";
	dollars = makeDynMixed("$DPE", dpe,
						   "$systemName", dollarParameterSystemName);
	XmlPanelTools_AddSymbol(listId, refFileNameForRowTable, panelReferenceName,"", dollars, 
							currentX, currentY);
}

void KnpGenerator_AddTheBeforeAfterCellToRowLu(mapping &listId, int currentX, int currentY)
{
	uint rootNode;
	string panelReferenceName, refFileNameForRowTable;
	rootNode = listId["rootNodeDocument"];
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	refFileNameForRowTable = "objects/TOSymbolsStatic/tnKNP_luZdvP.xml";
	XmlPanelTools_AddSymbol(listId, refFileNameForRowTable, panelReferenceName,"", "", currentX, 
							currentY);
}

void KnpGenerator_AddPressureForZdv(mapping &listId, string dpe, string dollarParameterSystemName, 
									int currentX, int currentY)
{
	uint rootNode;
	dyn_mixed dollars;
	string panelReferenceName;
	rootNode = listId["rootNodeDocument"];
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	dollars = makeDynMixed("$DPE", dpe,
						   "$kPressure", "$kPressure",
						   "$systemName", dollarParameterSystemName);
	XmlPanelTools_AddSymbol(listId, RefFileNamePressure, panelReferenceName, "", dollars, currentX, 
							currentY);
	currentX += 126;
	XmlPanelTools_AddSymbol(listId, RefFileNameMinMaxPressure, panelReferenceName, "", dollars, 
							currentX, currentY);
}

void KnpGenerator_AddVoltageForZdv(mapping &listId, string positionOfColumn, string dpe, string dollarParameterSystemName,
								   int currentX, int currentY)
{
	//рисуем плашку с именем СКЗ
	string descriptionSKZ = WinCC_GetDescription(SysNameSMT, dpe);
	dyn_string splitPointDescr = strsplit(descriptionSKZ, ".");
	string nameSKZ = splitPointDescr[2];
	KnpGenerator_AddNameEsuOrVoltage(listId, positionOfColumn, nameSKZ, currentX, currentYvoltage);
	//рисуем саму ЗДВ
	uint rootNode;
	dyn_mixed dollars;
	string panelReferenceName, refFileNameForRowTable;
	rootNode = listId["rootNodeDocument"];
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	refFileNameForRowTable = "objects/TOSymbolsGroup/tnKNP_luInfo_minMax2H.xml";
	dollars = makeDynMixed("$DPE", dpe,
						   "$kPressure", 1,
						   "$systemName", SysNameSMT);
	XmlPanelTools_AddSymbol(listId, refFileNameForRowTable, panelReferenceName, "", dollars, 
							currentX, currentYvoltage + 23);
	currentYvoltage += 69;
}

void KnpGenerator_AddESUForZdv(mapping &listId, string positionOfColumn, string dpe, string dollarParameterSystemName,
								   int currentX, int currentY)
{
	//рисуем плашку с именем ЕСУ 
	string descriptionESU = WinCC_GetDescription(dollarParameterSystemName, dpe);
	dyn_string splitPointDescr = strsplit(descriptionESU, ".");
	string nameESU = splitPointDescr[2];
	KnpGenerator_AddNameEsuOrVoltage(listId, positionOfColumn, nameESU, currentX, currentYesu);
	//рисуем саму ЕСУ
	uint rootNode;
	dyn_mixed dollars;
	string panelReferenceName, refFileNameForRowTable;
	rootNode = listId["rootNodeDocument"];
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	refFileNameForRowTable = "objects/TOSymbolsGroup/tnKNP_luFloat_minMax2H.xml";
	dollars = makeDynMixed("$DPE", dpe,
						   "$kPressure", 1,
						   "$systemName", dollarParameterSystemName);
	XmlPanelTools_AddSymbol(listId, refFileNameForRowTable, panelReferenceName, "", dollars, 
							currentX, currentYesu + 23);

	currentYesu += 69;
}

void KnpGenerator_AddAlarmForZdv(mapping &listId, string dpe, string dollarParameterSystemName, float countOfZdv,
								 int currentX, int currentY)
{
	dyn_float transformValueToDynFloat;
	dyn_mixed dollars;
	int refShapeSerial;
	string panelReferenceName, transformValueToString;
	uint rootNode, currentReferenceNode;
	rootNode = listId["rootNodeDocument"];
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	dollars = makeDynMixed("$DPE", dpe,
						   "$systemName", dollarParameterSystemName);
	
	refShapeSerial = KnpGeneratorConstants_ValuesForTableComponents["ЛУ"]["Вскрытие1"]
															["RefShapeSerial1"];
	currentReferenceNode = XmlPanelTools_AddSymbol(listId, RefFileNameAlarm, panelReferenceName, "", dollars, currentX, 
							currentY);
	/*******************************************************************************************************************/
	//меняем форму примитива для вскрытия ПКУ и отсутсвия напряжения (растягиваем на все КП)

	transformValueToDynFloat = KnpGeneratorConstants_ValuesForTableComponents["ЛУ"]["Вскрытие1"]
																		   ["Transform1"];
	transformValueToDynFloat[2] = countOfZdv;
	transformValueToDynFloat[4] -= (countOfZdv - 1) * currentY;
	transformValueToString = KnpGenerator_FloatGeometryToString(transformValueToDynFloat);
	KnpGenerator_AddShapeWithTransformProperty(rootNode, currentReferenceNode, refShapeSerial, 
											   transformValueToString, true);

	refShapeSerial = KnpGeneratorConstants_ValuesForTableComponents["ЛУ"]["Вскрытие2"]
															["RefShapeSerial2"];
	KnpGenerator_AddShapeWithTransformProperty(rootNode, currentReferenceNode, refShapeSerial, 
											   transformValueToString, true);
	/******************************************************************************************************************/																		   
}

void KnpGenerator_AddNumberOfKp(mapping &listId, string kmNum, string kpNum, float countOfZdv, 
								int currentX, int currentY)
{
	dyn_mixed dollars;
	int refShapeSerial;
	dyn_float transformValueToDynFloat;
	uint rootNode, currentReferenceNode;
	string panelReferenceName, refFileNameForRowTable, transformValueToString;
	dollars = makeDynMixed("$KM", kmNum,
						   "$KP", kpNum);
	rootNode = listId["rootNodeDocument"];
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	refFileNameForRowTable = "objects/TOSymbolsStatic/tnKNP_capKP.xml";
	refShapeSerial = KnpGeneratorConstants_ValuesForTableComponents["ЛУ"]["КП"]
															["RefShapeSerial1"];
	currentReferenceNode = XmlPanelTools_AddSymbol(listId, refFileNameForRowTable, 
												   panelReferenceName, "", dollars, currentX, 
												   currentY);
	transformValueToDynFloat = KnpGeneratorConstants_ValuesForTableComponents["ЛУ"]["КП"]
																		   ["Transform1"];
	transformValueToDynFloat[2] = countOfZdv;
	transformValueToDynFloat[4] -= (countOfZdv - 1) * currentY;
	transformValueToString = KnpGenerator_FloatGeometryToString(transformValueToDynFloat);
	KnpGenerator_AddShapeWithTransformProperty(rootNode, currentReferenceNode, refShapeSerial, 
											   transformValueToString);
}

void KnpGenerator_AddKp(mapping &listId, dyn_dyn_string dataForCreating,
					 	string dollarParameterSystemName, int &currentX, int &currentY)
{
	currentY = currentY + 2; //промежуток между строками КП нужен для корректного отображения толстой линии разграничивающей КП
	int startX, startY;
	CountOfZdvOnEachKp = 0;
	dynClear(countRowInKP);
	//if(currentY < currentYvoltage)
	//	currentY = currentYvoltage;
	startX = currentX;
	startY = currentY;
	currentYvoltage = currentY;
	currentYesu = currentY;
	for (int i = 1; i <= dynlen(dataForCreating); i++)
	{
		if((dataForCreating[i][3] == "") || ((dataForCreating[i][3] != "") && (dataForCreating[i][4] != "")))
		{
			currentX = startX + 46;
			KnpGenerator_CreateRowOfKp(listId, dataForCreating[i], dollarParameterSystemName,
									   currentX, currentY);
			
		//если это строка содержит КПСОД и больше ничего, то сдвигаемся только на пол строки
			if(dataForCreating[i][4] != "") //&& ((dataForCreating[i][9] == "") && (dataForCreating[i][10] == "") && (dataForCreating[i][11] == "")))
				currentY += 23;
			else
				currentY += 46;
		}
	}
	//найти самый длинный столбец и взять его за основной
	if(currentY < currentYvoltage)
		currentY = currentYvoltage;
	if(currentY < currentYesu)
		currentY = currentYesu;
	CountOfZdvOnEachKp = dynMax(countRowInKP); //нахождение столбца максимального
	for (int i = 1; i <= dynlen(dataForCreating); i++)
	{
		if(dataForCreating[i][10] != "")
			KnpGenerator_AddAlarmForZdv(listId, dataForCreating[i][10],	dollarParameterSystemName, CountOfZdvOnEachKp, startX + 795, startY);// добавляем аварию открытия
		if(dataForCreating[i][11] != "")
			KnpGenerator_AddAlarmForZdv(listId, dataForCreating[i][11],	dollarParameterSystemName, CountOfZdvOnEachKp, startX + 901, startY);// добавляем аварию напряжения
	}
	KnpGenerator_AddLineForDivideKP(listId,  startX, startY - 1); //рисуем линию между КП
	KnpGenerator_AddNumberOfKp(listId, dataForCreating[1][2], dataForCreating[1][3],
							   CountOfZdvOnEachKp, startX, startY);
}
// передаем строку из csv и строим строку таблицы для ТУ
void KnpGenerator_CreateRowOfKp(mapping &listId, dyn_string dataForCreating,
					 			string dollarParameterSystemName, int &currentX, int currentY)
{
	for (int i = 4; i <= dynlen(dataForCreating); i++)//перебор в ячеек в строке
	{
		if (dataForCreating[i] != "")
		{
			switch(i)
			{
				case 4:
					KnpGenerator_AddKpsod(listId, dataForCreating[i], 
												dataForCreating[5], dollarParameterSystemName, 
												currentX, currentY);
					countRowInKP[1] += 0.5; //пересчет всех КПСОДов и прибавление их к задвижкам (0,5 потому что они высотой в пол строки)
					break;
				case 5:
					if(dataForCreating[4] == "")
					{
						KnpGenerator_AddZdv(listId, dataForCreating[i], currentX, currentY);
						countRowInKP[1]++;//пересчет всех задвижек
					}
					break;
				case 6:
					KnpGenerator_AddZdvStateToRowLu(listId, dataForCreating[i], 
												dollarParameterSystemName, currentX, currentY);
					break;
				case 7:
					KnpGenerator_AddPressureForZdv(listId, dataForCreating[i],
												dollarParameterSystemName, currentX, currentY);
					break;
				case 8:
					KnpGenerator_AddPressureForZdv(listId, dataForCreating[i],
												dollarParameterSystemName, currentX - 315, 
												currentY + 23);
					break;
				case 9:
					KnpGenerator_AddVoltageForZdv(listId, "SKZ", dataForCreating[i], 
												 dollarParameterSystemName, currentX, currentY);
					countRowInKP[2] += 1.5; //пересчет всех СКЗ
					break;
				case 12:
					KnpGenerator_AddESUForZdv(listId, "ESU", dataForCreating[i], 
												 dollarParameterSystemName, currentX, currentY);
					countRowInKP[3] += 1.5;//пересчет всех ЕСУ
					break;
			}
		}
		KnpGenerator_CreateRowOfKpChangeCurrentX(listId, i, dataForCreating,currentX, currentY);
	}
	
}


void KnpGenerator_AddNameEsuOrVoltage(mapping &listId, string positionOfColumn,  string nameESU, int currentX, int &currentY)
{	
	dyn_mixed dollars;
	dyn_float geometry;
	uint currentReferenceNode;
	dyn_dyn_float transformValueToDynFloat;
	int refShapeSerial, currentPosX, currentPosY;
	string groupPath, refFileName, panelReferenceName, titleText;
	titleText = "ЕСУ";
	refFileName = "objects_parts/TOSymbols/tnKNP_tableTitle.xml";
	panelReferenceName = "PANEL_REF" + listId["referenceId"];								  
	geometry = KnpGeneratorConstants_ValuesForTableComponents["ЛУ"]["Имя ЕСУ"]["Geometry"];
	currentPosX = KnpGeneratorConstants_ValuesForTableComponents["ЛУ"]["Имя ЕСУ"]["Location"][1];
	currentPosY = KnpGeneratorConstants_ValuesForTableComponents["ЛУ"]["Имя ЕСУ"]["Location"][2];	
	geometry[3] += currentX; geometry[4] += currentY;
	if (nameESU != "")
		titleText = nameESU;
	dollars = makeDynMixed("$titleText", "\"" + titleText + "\"");
	currentReferenceNode = XmlPanelTools_AddSymbol(listId, refFileName, panelReferenceName,         
												   geometry, dollars, currentPosX, currentPosY);
	for (int i = 1; i <= 2; i++)
	{
		transformValueToDynFloat[i] = KnpGeneratorConstants_ValuesForTableComponents["ЛУ"]["Имя ЕСУ"]
																				  ["Transform" + i];
		refShapeSerial = KnpGeneratorConstants_ValuesForTableComponents["ЛУ"]["Имя ЕСУ"]
																	   ["RefShapeSerial" + i];
		if (i == 1)
		{
			if(positionOfColumn == "SKZ")
				transformValueToDynFloat[i][3] -= 1.774295999201278 * currentX;
			else transformValueToDynFloat[i][3] -= 1.69355092064 * currentX;
		}	//2.3595 *
		KnpGenerator_AddTransformShapeToKpsod(listId, currentReferenceNode,
											  transformValueToDynFloat[i], refShapeSerial);
	}
}	


void KnpGenerator_CreateRowOfKpChangeCurrentX(mapping &listId, int index, dyn_string rowComponents, int &currentX,
											  int currentY)
{
	switch (index)
	{
		case 5:
			currentX += 46;
			break;
		case 6:
		{
			currentX += 146;
			if((rowComponents[4] == "") && (rowComponents[5] != ""))
				KnpGenerator_AddTheBeforeAfterCellToRowLu(listId, currentX, currentY);
			currentX += 53;
		}
			break;
		case 7:
			currentX += 315;
			break;
		case 9:
			currentX += 189;
			break;
		case 10: case 11: case 12:
			currentX += 106;
			break;
	}	
}

void KnpGenerator_CreateBorderForLu(mapping &listId, string nameOfLu, int currentX, int currentY,
									int width, int height)
{
	string tableName;
	float coefficientX;
	tableName = "ЛУ"; 
	coefficientX = 0.276;
	KnpGenerator_AddCaptionOverBorder(listId, tableName, nameOfLu, coefficientX, currentX, 
									  currentY);
	currentY += 46;
	mapping props = makeMapping("RefPoint", currentX - 10 + " " + currentY,
								"ForeColor", "yellow",
								"BackColor", "_Transparent",
								"Location", currentX - 10 + " " + currentY,
								"Size", width + " " + height,
								"serialId", 0,
								"TabOrder", 0);
	XmlPanelTools_AddShape(listId, "RECTANGLEBORDER", "RECTANGLE", props);
}

void KnpGenerator_AddControlButtonsForLu(mapping &listId, dyn_string dataForCreating, int currentX, 
										 int currentY)
{
	dyn_mixed dollars;
	uint rootNode, currentReferenceNode;
	string panelReferenceName, refFileNameForRowTable;
	rootNode = listId["rootNodeDocument"];
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	refFileNameForRowTable = "objects/TOSymbols/tnKNP_luControl.xml";
	dollars = makeDynMixed("$LU", dataForCreating[4],
						   "$systemName", dataForCreating[3],
						   "$titleText", "\"" + dataForCreating[2] + "\"");
	currentReferenceNode = XmlPanelTools_AddSymbol(listId, refFileNameForRowTable, 
												   panelReferenceName, "", dollars, currentX,
												   currentY);	
}


void KnpGenerator_AddControlButtonsForNps(mapping &listId, dyn_string dataForCreating, 
										 int currentX, int currentY)
{
	uint rootNode = listId["rootNodeDocument"];
	string panelReferenceName = "PANEL_REF" + listId["referenceId"];
	string refFileNameForRowTable = "objects/TOSymbols/tnKNP_luControl.xml";
	dyn_mixed dollars = makeDynMixed(
							"$LU", dataForCreating[4],
							"$systemName", dataForCreating[3],
							"$titleText", "\"" + dataForCreating[2] + "\""
						);
	uint currentReferenceNode = XmlPanelTools_AddSymbol(listId, refFileNameForRowTable, 
														panelReferenceName, "", dollars,
														currentX, currentY);
}


void KnpGenerator_AddBackColorShapeToLu(mapping &listId, int currentX, int currentY, mapping size)
{
	mapping props = makeMapping("RefPoint", currentX + " " + currentY,
								"ForeColor", "yellow",
								"BackColor", "{159,159,159}",
								"Location", currentX + " " + currentY,
								"LineType", "[solid,oneColor,JoinBevel,CapProjecting,3]",
								"Size", size["width"] + " " + size["height"],
								"serialId", 0,
								"TabOrder", 0);
	XmlPanelTools_AddShape(listId, "RECTANGLEBACKCOLOR", "RECTANGLE", props);	
}

void KnpGenerator_CreateBorderAndHeaderToLu(mapping &listId, dyn_dyn_string dataForCreating, 
												  string nameOfLu, int currentX, int currentY)
{
	mapping sizeForBorderLu;
	int positionXForBorderLu, positionYForBorderLu, widthForBorderLu, 
		heightForBorderLu, positionXForControlButtons, positionYForControlButtons;
	sizeForBorderLu = KnpGenerator_GetBorderLuSize(dataForCreating);
	positionXForBorderLu = currentX;
	positionYForBorderLu = currentY - 60;
	widthForBorderLu = sizeForBorderLu["width"] + 27;
	heightForBorderLu = sizeForBorderLu["height"] + 22;
	positionXForControlButtons = positionXForBorderLu + sizeForBorderLu["width"] - 231;
	positionYForControlButtons = currentY - 43;
	KnpGenerator_AddBackColorShapeToLu(listId, currentX - 1, currentY, sizeForBorderLu);
	KnpGenerator_CreateBorderForLu(listId, nameOfLu, positionXForBorderLu, positionYForBorderLu,
								   widthForBorderLu, heightForBorderLu);
	KnpGenerator_AddControlButtonsForLu(listId, dataForCreating[1], positionXForControlButtons,
										positionYForControlButtons);
	KnpGenerator_AddStandardHeadLu(listId, currentX, currentY);
	KnpGenerator_CheckAlarmUAndEsu(listId, dataForCreating, currentX, currentY);
}

mapping KnpGenerator_GetBorderLuSize(dyn_dyn_string dataForCreating)
{
	mapping resultMap;
	int tempWidth, maxWidth, maxHeigt, height, heightESU, heightSKZ;
	tempWidth = 47; 
	float height = 47; heightESU = 47; heightSKZ = 47;
	for (int i = 2; i <= dynlen(dataForCreating); i++)
	{
		if (dataForCreating[i][2] == "" && dataForCreating[i][4] == "")
			height += 46;
		for (int j = 2; j <= dynlen(dataForCreating[i]); j++)
		{
			if (j != dynlen(dataForCreating[i]) || dataForCreating[i][j] != "")
			{
				switch (j)
				{
					case 2:
						if (dataForCreating[i][j] != "")
						{
							height += 3;
						}
						break;
					case 4:
						if (dataForCreating[i][j] != "")
							height += 23;
						break;
					case 5:
						tempWidth += 46;
						break;
					case 6:
						tempWidth += 146;
						break;
					case 7:
						tempWidth += 368;
						break;
					case 9:
						if (dataForCreating[i][j] != "")
							heightSKZ += 71;
						tempWidth += 189;
						break;
					case 10: case 11:
						tempWidth += 107;
						break;
					case 12:
						if (dataForCreating[i][j] != "")
							heightESU += 71;
						tempWidth += 189;
						break;
				}
			}
		}
		if(dataForCreating[i][2] != "" || i == dynlen(dataForCreating))
		{	
			maxHeigt = KnpGenerator_Max(heightSKZ, heightESU);
			maxHeigt = KnpGenerator_Max(maxHeigt, height);
			height = maxHeigt;
			heightSKZ = maxHeigt;
			heightESU = maxHeigt;
		}
		maxWidth = KnpGenerator_Max(maxWidth, tempWidth);
		tempWidth = 47;
	}	
	resultMap = makeMapping("width", maxWidth,
							"height", height);
	return resultMap;
}

void KnpGenerator_CreateRowsToLu(mapping &listId, dyn_dyn_string dataForCreating,
								 string dollarParameterSystemName, int &currentX, int &currentY)
{
	int startX, startY, i;
	dyn_dyn_string creatingTable;
	startX = currentX; startY = currentY; i = 1;
	while (i < dynlen(dataForCreating))
	{	
		dynAppend(creatingTable, dataForCreating[i]);
		if (dataForCreating[i + 1][2] != "")
		{
			KnpGenerator_AddKp(listId, creatingTable, dollarParameterSystemName,
							   currentX, currentY);
			dynClear(creatingTable);
		}
		currentX = startX;
		i++;
	}
	dynAppend(creatingTable, dataForCreating[i]);	
	KnpGenerator_AddKp(listId, creatingTable, dollarParameterSystemName, currentX, currentY);
}

void KnpGenerator_CheckAlarmUAndEsu(mapping &listId, dyn_dyn_string dataForCreating, int currentX, 
									int currentY)
{
	int startX = currentX;
	dyn_bool alarmUAndEsuSearchingStatus = makeDynBool(false, false);
	for (int i = 1; i <= dynlen(dataForCreating); i++)
	{
		for (int j = 1; j <= dynlen(dataForCreating[i]); j++)
		{
			if (patternMatch("*.Alm.AlmSupply.AlarmU220Vvod1", dataForCreating[i][j]))
				alarmUAndEsuSearchingStatus[1] = true;	
			if (patternMatch("*.TI.Hoil", dataForCreating[i][j]))
				alarmUAndEsuSearchingStatus[2] = true;	
		}
		if (alarmUAndEsuSearchingStatus[1] && alarmUAndEsuSearchingStatus[2])
			break;
	}
	if (alarmUAndEsuSearchingStatus[1])
	{
		currentX = startX + 907;
		KnpGenerator_AddAlarmUToHeadLu(listId, currentX, currentY);
	}
	if (alarmUAndEsuSearchingStatus[2])
	{
		currentX = startX + 1007;
		KnpGenerator_AddEsuToHeadLu(listId, currentX, currentY);
	}
}

void KnpGenerator_CreateHeadSikn(mapping &listId, int currentX, int &currentY)
{
	KnpGenerator_AddPressureToHeadSikn(listId, currentX, currentY);
	KnpGenerator_AddWaterPrcToHeadSikn(listId, currentX, currentY);
	KnpGenerator_AddRoToHeadSikn(listId, currentX, currentY);
	KnpGenerator_AddViscToHeadSikn(listId, currentX, currentY);
	KnpGenerator_AddSulfToHeadSikn(listId, currentX, currentY);
	KnpGenerator_AddSaltToHeadSikn(listId, currentX, currentY);
	currentY += 46;
}

void KnpGenerator_AddPressureToHeadSikn(mapping &listId, int &currentX, int currentY)
{
	uint rootNode, currentReferenceNode, refShapeSerial;
	string transformValueString, langText, refFileName, panelReferenceName;
	refShapeSerial = 3;
	langText = "Расход по ИЛ";
	rootNode = listId["rootNodeDocument"];
	transformValueString = "1 0 0 1 -12 1.25";
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	refFileName = "objects/TOSymbolsStatic/tnKNP_nsHeaderP.xml";
	currentReferenceNode = XmlPanelTools_AddSymbol(listId, refFileName, panelReferenceName, "", "", 
												   currentX, currentY);
	KnpGenerator_CreateLangTextForTable(listId, langText, transformValueString, refShapeSerial,
										currentReferenceNode);
	currentX += 280;	
}

void KnpGenerator_AddWaterPrcToHeadSikn(mapping &listId, int &currentX, int currentY)
{
	float coefficientX;
	string refFileName;
	coefficientX = 1.3737;
	refFileName = "objects/TOSymbolsStatic/tnKNP_luZdvP_1.xml";
	KnpGenerator_AddTransformingCellToHeadTableWithLangText(listId, refFileName, "СИКН", 
															"Содержание воды", "",
															"Содержание воды", coefficientX, 
															currentX, currentY);
	currentY += 22;
	KnpGenerator_AddCurrentSlashMaxToHeadSikn(listId, currentX, currentY);
	currentX += 128;
}

void KnpGenerator_AddRoToHeadSikn(mapping &listId, int &currentX, int currentY)
{
	uint currentReferenceNode, refShapeSerial;
	string transformValueString, langText, refFileName, panelReferenceName;
	refShapeSerial = 100;
	langText = "Плотность";
	transformValueString = "1 0 0 1 30 0";
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	refFileName = "objects/TOSymbolsStatic/tnKNP_luHeaderZdvP_2.xml";
	currentReferenceNode = XmlPanelTools_AddSymbol(listId, refFileName, panelReferenceName, "", "", 
												   currentX, currentY);
	KnpGenerator_CreateLangTextForTable(listId, langText, transformValueString, refShapeSerial,
										currentReferenceNode);
	currentX += 187;
}

void KnpGenerator_AddViscToHeadSikn(mapping &listId, int &currentX, int currentY)
{
	float coefficientX;
	string refFileName;
	coefficientX = 1.3778;
	refFileName = "objects/TOSymbolsStatic/tnKNP_luZdvP_1.xml";
	KnpGenerator_AddTransformingCellToHeadTableWithLangText(listId, refFileName, "СИКН", "Вязкость", 
															"", "Вязкость", coefficientX, currentX, 
															currentY);
	currentY += 22;
	KnpGenerator_AddCurrentSlashMaxToHeadSikn(listId, currentX, currentY);
	currentX += 125;
}

void KnpGenerator_AddSulfToHeadSikn(mapping &listId, int &currentX, int currentY)
{
	float coefficientX;
	string refFileName;
	coefficientX = 1.3737;
	refFileName = "objects/TOSymbolsStatic/tnKNP_luZdvP_1.xml";
	KnpGenerator_AddTransformingCellToHeadTableWithLangText(listId, refFileName, "СИКН", 
															"Содержание серы", "", 
															"Содержание серы", coefficientX, 
															currentX, currentY);
	currentY += 22; currentX += 1;
	KnpGenerator_AddCurrentSlashMaxToHeadSikn(listId, currentX, currentY);
	currentX += 124;
}

void KnpGenerator_AddSaltToHeadSikn(mapping &listId, int &currentX, int currentY)
{
	float coefficientX;
	string refFileName;
	coefficientX = 1.3737;
	refFileName = "objects/TOSymbolsStatic/tnKNP_luZdvP_1.xml";
	KnpGenerator_AddTransformingCellToHeadTableWithLangText(listId, refFileName, "СИКН", 
															"Содержание солей", "", 
															"Содержание солей", coefficientX, 
															currentX, currentY);
	currentY += 22; currentX += 2;
	KnpGenerator_AddCurrentSlashMaxToHeadSikn(listId, currentX, currentY);
	currentX += 125;
}

void KnpGenerator_AddCurrentSlashMaxToHeadSikn(mapping &listId, int &currentX, int currentY)
{
	float coefficientX;
	dyn_float geometry;
	uint rootNode, currentReferenceNode;
	dyn_string transformValueToDynString;
	dyn_dyn_float transformValueToDynFloat;
	string refFileName, panelReferenceName;
	int currentPosX, currentPosY, refShapeSerial;
	refShapeSerial = 1;
	coefficientX = 0.996597;
	rootNode = listId["rootNodeDocument"];
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	refFileName = "objects/TOSymbolsStatic/tnKNP_siknHeader4.xml";
	currentPosX = KnpGeneratorConstants_ValuesForTableComponents["СИКН"]["Текущ./Макс."]
																		 ["Location"][1];
	currentPosY = KnpGeneratorConstants_ValuesForTableComponents["СИКН"]["Текущ./Макс."]
																		 ["Location"][2];									  
	geometry = KnpGeneratorConstants_ValuesForTableComponents["СИКН"]["Текущ./Макс."]["Geometry"];
	geometry[3] += currentX; geometry[4] += currentY;
	currentReferenceNode = XmlPanelTools_AddSymbol(listId, refFileName, panelReferenceName,
												   geometry, "", currentPosX, currentPosY);
	transformValueToDynFloat[1] = KnpGeneratorConstants_ValuesForTableComponents["СИКН"]
														  ["Текущ./Макс."]["Transform1"];
	transformValueToDynFloat[1][3] += coefficientX * currentX;
	transformValueToDynString[1] = KnpGenerator_FloatGeometryToString(transformValueToDynFloat[1]);
	KnpGenerator_AddShapeWithTransformProperty(rootNode, currentReferenceNode, refShapeSerial, 
											   transformValueToDynString[1]);
}

void KnpGenerator_AddTransformingCellToHeadTableWithLangText(mapping &listId, 
															 string refFileNameForHeadTable,
															 string tableName, 
															 string componentOfHeadTable, 
															 dyn_mixed dollars, string langText, 
															 float coefficient, int currentX, 
															 int currentY)
{
	dyn_float geometry;
	string panelReferenceName;
	uint rootNode, currentReferenceNode;
	dyn_string transformValueToDynString;
	dyn_dyn_float transformValueToDynFloat;
	int currentPosX, currentPosY, refShapeSerial;
	rootNode = listId["rootNodeDocument"];
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	geometry = KnpGeneratorConstants_ValuesForTableComponents[tableName][componentOfHeadTable]
																				  ["Geometry"];
	geometry[3] += currentX; geometry[4] += currentY;
	currentPosX = KnpGeneratorConstants_ValuesForTableComponents[tableName][componentOfHeadTable]
																				  ["Location"][1];
	currentPosY = KnpGeneratorConstants_ValuesForTableComponents[tableName][componentOfHeadTable]
																				  ["Location"][2];
	currentReferenceNode = XmlPanelTools_AddSymbol(listId, refFileNameForHeadTable, 
												   panelReferenceName, geometry, dollars, 
												   currentPosX, currentPosY);
	transformValueToDynFloat[1] = KnpGeneratorConstants_ValuesForTableComponents[tableName]
													   [componentOfHeadTable]["Transform1"];
	transformValueToDynFloat[2] = KnpGeneratorConstants_ValuesForTableComponents[tableName]
													   [componentOfHeadTable]["Transform2"];
	if (coefficient != 0) 
		transformValueToDynFloat[1][3] -= coefficient * currentX;
	transformValueToDynString[1] = KnpGenerator_FloatGeometryToString(transformValueToDynFloat[1]);
	transformValueToDynString[2] = KnpGenerator_FloatGeometryToString(transformValueToDynFloat[2]);
	refShapeSerial = KnpGeneratorConstants_ValuesForTableComponents[tableName][componentOfHeadTable]
																		 		["RefShapeSerial1"];
	KnpGenerator_AddShapeWithTransformProperty(rootNode, currentReferenceNode, refShapeSerial, 
											   transformValueToDynString[1]);
	refShapeSerial = KnpGeneratorConstants_ValuesForTableComponents[tableName][componentOfHeadTable]
																	 			["RefShapeSerial2"];
	KnpGenerator_CreateLangTextForTable(listId, langText, transformValueToDynString[2], 
										refShapeSerial, currentReferenceNode);
}

void KnpGenerator_AddRowSikn(mapping &listId, dyn_string dataForCreating,
							 string dollarParameterSystemName, int currentX, int &currentY)
{
	int stepX;
	dyn_mixed dollars;
	string panelReferenceName, refFileName, kPressure;
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	refFileName = "objects_parts/TOSymbols/tnKNP_tableTitle.xml";
	dollars = makeDynMixed("$titleText", "\"" + dataForCreating[2] + "\"");
	XmlPanelTools_AddSymbol(listId, refFileName, panelReferenceName, "", dollars, currentX, 
							currentY);
	currentX += 73;
	for (int i = 3; i <= dynlen(dataForCreating); i++)
	{
		if (dataForCreating[i] != "")
		{
			switch (i)
			{
				case 3: case 5:
					refFileName = "objects/TOSymbolsGroup/tnKNP_luFloat_minMax.xml";
					kPressure = "1";
					stepX = 189;
					break;
				default:
					refFileName = "objects/TOSymbolsGroup/tnKNP_luFloat_max.xml";
					kPressure = "1";
					stepX = 126;
					break;
			}
			if (i == 3)
				stepX += 20;
			dollars = makeDynMixed("$DPE", dataForCreating[i],
								   "$kPressure", kPressure,
								   "$systemName", dollarParameterSystemName);
			KnpGenerator_AddCellToRowSikn(listId, refFileName, dollars, currentX, currentY);
		}
		currentX += stepX;
	}
	currentY += 23;
}

void KnpGenerator_AddCellToRowSikn(mapping &listId, string refFileName, dyn_mixed dollars,
							  	   int currentX, int currentY)
{
	string panelReferenceName = "PANEL_REF" + listId["referenceId"];
	XmlPanelTools_AddSymbol(listId, refFileName, panelReferenceName, "", dollars, currentX,
							currentY);
}

void KnpGenerator_CreateBorderForSikn(mapping &listId, string nameOfSikn, int currentX, 
									  int currentY, int width, int height)
{
	string tableName;
	float coefficientX;
	tableName = "СИКН"; 
	coefficientX = 0.276;
	KnpGenerator_AddCaptionOverBorder(listId, tableName, nameOfSikn, coefficientX, currentX, 
									  currentY);
	currentY += 46;
	mapping props = makeMapping(
				"RefPoint", currentX + " " + currentY,
				"ForeColor", "yellow",
				"BackColor", "_Transparent",
				"Location", currentX + " " + currentY,
				"Size", width + " " + height,
				"serialId", 0,
				"TabOrder", 0);
	XmlPanelTools_AddShape(listId, "RECTANGLEBORDER", "RECTANGLE", props);	
}

void KnpGenerator_AddCaptionOverBorder(mapping &listId, string tableName, string nameOfObject, 
									   float coefficientX, int currentX, int currentY)
{
	dyn_mixed dollars;
	dyn_float geometry;
	dyn_int refShapeSerials;
	int captionX, captionY;
	uint rootNode, currentReferenceNode;
	dyn_string transformValueToDynString;
	dyn_dyn_float transformValueToDynFloat;
	string panelReferenceName, refFileNameForRowTable;
	rootNode = listId["rootNodeDocument"];
	refShapeSerials[1] = KnpGeneratorConstants_ValuesForCaptionAboveBorder[tableName]
																  ["RefShapeSerial1"];
	refShapeSerials[2] = KnpGeneratorConstants_ValuesForCaptionAboveBorder[tableName]
																  ["RefShapeSerial2"];
	geometry = KnpGeneratorConstants_ValuesForCaptionAboveBorder[tableName]["Geometry"];
	captionX = KnpGeneratorConstants_ValuesForCaptionAboveBorder[tableName]["Location"][1]; 
	captionY = KnpGeneratorConstants_ValuesForCaptionAboveBorder[tableName]["Location"][2];
	transformValueToDynFloat[1] = KnpGeneratorConstants_ValuesForCaptionAboveBorder[tableName]
																		   		["Transform1"];
	transformValueToDynFloat[2] = KnpGeneratorConstants_ValuesForCaptionAboveBorder[tableName]
																		   		["Transform2"];
	geometry[3] += currentX; geometry[4] += currentY;
	transformValueToDynFloat[1][3] -= currentX * coefficientX;
	panelReferenceName = "PANEL_REF" + listId["referenceId"];
	dollars = makeDynMixed("$luName", "\"" + nameOfObject + "\"");
	refFileNameForRowTable = "objects/TOSymbolsStatic/tnKNP_capLU.xml";
	transformValueToDynString[1] = KnpGenerator_FloatGeometryToString(transformValueToDynFloat[1]);
	transformValueToDynString[2] = KnpGenerator_FloatGeometryToString(transformValueToDynFloat[2]);
	currentReferenceNode = XmlPanelTools_AddSymbol(listId, refFileNameForRowTable, 
												   panelReferenceName, geometry, dollars, 
												   captionX, captionY);
	KnpGenerator_AddShapeWithTransformProperty(rootNode, currentReferenceNode, refShapeSerials[1], 
											   transformValueToDynString[1]);
	KnpGenerator_AddShapeWithTransformProperty(rootNode, currentReferenceNode, refShapeSerials[2], 
											   transformValueToDynString[2]);		
}

KnpGenerator_GenerateSikn(mapping &listId, dyn_dyn_string dataForCreating, string nameOfSikn,
						  string dollarParameterSystemName, int &currentX, int &currentY)
{
	dyn_dyn_string creatingTable;
	int startX, startY, width, height, i, borderX, borderY;
	height = (dynlen(dataForCreating) - 1) * 24 + 72; 
	borderX = currentX - 10; borderY = currentY - 60;
	startX = currentX; startY = currentY; width = BorderWidthForSikn; i = 2;
	KnpGenerator_CreateBorderForSikn(listId, nameOfSikn, borderX, borderY, width, height);
	KnpGenerator_CreateHeadSikn(listId, currentX, currentY);
	while (i < dynlen(dataForCreating))
	{
		dynAppend(creatingTable, dataForCreating[i]);
		if (dataForCreating[i + 1][2] != "")
		{
			KnpGenerator_AddRowSikn(listId, dataForCreating[i], dollarParameterSystemName, 
									currentX, currentY);
			dynClear(creatingTable);
		}
		i++;
	}
	dynAppend(creatingTable, dataForCreating[i]);	
	KnpGenerator_AddRowSikn(listId, dataForCreating[i], dollarParameterSystemName, 
							currentX, currentY);	
}

void KnpGenerator_AddLineForDivideKP(mapping &listId, int currentX, int currentY)
{
	string panelReferenceName, fileName;
	mapping props = makeMapping(
				"RefPoint", currentX + " " + currentY,
				"ForeColor", "yellow",
				"BackColor", "{159,159,159}",
				"serialId", 0,
				"TabOrder", 0,
				"LineType", "[solid,oneColor,JoinBevel,CapProjecting,3]",
				"Start", currentX + " " + currentY,
				"End", "1216  " + currentY,
				"RefPoint", currentX + " " + currentY);	
	XmlPanelTools_AddShape(listId, "LINE", "LINE", props);
}

//получаем описание точки данных
string WinCC_GetDescription(string systemName, string dpe)
{
	string description = " . ";
	dyn_string splitPoint = strsplit(dpe, ".");
	string fullDpe  = systemName + splitPoint[1];

	if(!dpExists(fullDpe))
		DebugN("Not found DP: " + fullDpe);
	else
		description = dpGetDescription(fullDpe + ".");
	return description;
}
