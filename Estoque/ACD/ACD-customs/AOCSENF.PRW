/*_______________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------+------------+-------+----------------------+------+------------+¦¦
¦¦¦ Função    ¦  SENFAUX   ¦ Autor ¦ Edson P. S. Sales    ¦ Data ¦ 20/07/2022 ¦¦¦
¦¦+-----------+------------+-------+----------------------+------+------------+¦¦
¦¦¦ Descriçäo ¦     Rotina para Gerar documento SENF pós Doc-Aux  picklist    ¦¦¦
¦¦+-----------+---------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/
#INCLUDE 'RWMAKE.CH'    
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'APVT100.CH'   

/*/{Protheus.doc} User Function nomeFunction/*/
User Function AOCSENF()

    Local aTela 
    Local cDoc

    While !VTLastkey() == 27 // enquanto não apertar (ESC) ficar na tela para bipar
        cDoc := Space(6)
        VTClear()
        VTSave Screen To aTela

        @ 00,02 VTSay PadR('---GERAR SENF AUXILIAR---' , VTMaxCol())
        @ 01,00 VTSay PadR('Doc.: ', VTMaxCol())
        @ 01,07 VTGET cDoc  Pict '@!' VALID !EMPTY(cDoc) .and. fValDoc(cDoc)

        VTRead
        VTRestore Screen FROM aTela
    endDo
    
Return 

/* Validar se o documento existe */

******************************************************************************************************************************************************
Static Function fValDoc(cNumDoc)
*********************************************************************************************************************************************************************************************************************
    Local   cAliasDoc  := GetNextAlias()
    Local   lDoc :=.F.
     
    Local   cQry  := "SELECT ZT9.ZT9_DOCAUX DOC FROM " + RetSqlName('ZT9') + " ZT9  (NOLOCK) "
            cQry  += " WHERE  ZT9_DOCAUX = '" + cNumDoc +"' AND D_E_L_E_T_=''"

    cQry := ChangeQuery(cQry)
    dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQry),cAliasDoc, .T., .F.)

    dbSelectArea(cAliasDoc)

    DbSelectArea('ZT8')
    ZT8->(MsSeek(FWFilial('ZT8') + cNumDoc ))

    if Empty((cAliasDoc)->DOC)

        VTAlert('Documento informado nao existe!!!',"Atencao",.T.)  //  

    elseif  ZT8_STATUS=='1' // documento ja processado/Senf Gerada

        VTAlert('Documento informado já foi Processado!!!',"Atencao",.T.)

    else
        fgerar((cAliasDoc)->DOC)
        lDoc := .T.
    endif

   (cAliasDoc)->(dbCloseArea())
   dbSelectArea('ZT8')

Return 

/*/ {Protheus.doc} User Function nomeFunction /*/
Static Function fgerar(cNumDoc)

Local cQry1     :=''
Local  lResp := .F.
Local cAliasQry :=GetNextAlias()
local cNumSf := GetSXENum("ZT3", "ZT3_NUM")
Local nItem := 1
Local cEndDest :="EXPEDICAO" // DESTINO DO VOLUME APOS GERAR SENF


cQry1 +="  SELECT   COUNT(*) QUANT,  "
cQry1 +="           SB1.B1_UM UNIDADE,  "
cQry1 +="           SBF.BF_LOCAL ARMAZEM,   "
cQry1 +="           SBF.BF_LOCALIZ ENDERECO,    "
cQry1 +="           SBF.BF_LOTECTL LOTE,    "
cQry1 +="           SB1.B1_DESC DESCRICAO,  "
cQry1 +="           ZT9.ZT9_CODPRO PRODUTO ,  "
cQry1 +="           DA1_PRCVEN PRC_UNIT,   "
cQry1 +="           DA1_PRCVEN *  COUNT(*) AS PRC_TOTAL     " 
cQry1 +="  FROM " +RetSQLName('ZT9') +" ZT9  (NOLOCK) "
cQry1 +="       INNER JOIN " +RetSQLName('DA1') +" DA1 (NOLOCK) ON DA1.D_E_L_E_T_='' AND DA1.DA1_CODPRO = ZT9.ZT9_CODPRO AND DA1.DA1_CODTAB ='079'    "
cQry1 +="       INNER JOIN  " +RetSQLName('SB1') +" SB1 (NOLOCK) ON SB1.D_E_L_E_T_='' AND SB1.B1_COD = ZT9.ZT9_CODPRO  "
cQry1 +="       INNER JOIN  " +RetSQLName('SBF') +" SBF (NOLOCK) on SBF.D_E_L_E_T_='' AND SBF.BF_PRODUTO = ZT9.ZT9_CODPRO AND SBF.BF_LOCALIZ='SEPARACAO'  "
cQry1 +="  WHERE   ZT9.D_E_L_E_T_=''  and ZT9.ZT9_DOCAUX='" + cNumDoc +"'"
cQry1 +="  GROUP BY ZT9.ZT9_CODPRO,DA1_PRCVEN,SB1.B1_UM,SB1.B1_DESC,SBF.BF_LOCAL,SBF.BF_LOCALIZ,SBF.BF_LOTECTL  "
 
cQry1 := ChangeQuery(cQry1)
dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQry1),cAliasQry, .T., .F.)
dbSelectArea(cAliasQry)

if MsgYesNo('Tem Certeza que quer gerar SENF Auxiliar ?', 'Atencao!!!')
    DbSelectArea('ZT3')
        
    VTMSG("Aguarde...")
	vBaixaReg  := 0
	vBaixaAcum := 0

    Begin Transaction

        //DbSetOrder(1)
        RecLock('ZT3',.T.)
            ZT3_FILIAL := FWFILIAL('ZT3')
            ZT3_NUM    := cNumSf
            ZT3_TPSENF := 'Rem.Armz.'
            ZT3_TIPO   := 'B'
            ZT3_DATA   := DATE()
            ZT3_CODCF  := '02462805'
            ZT3_LOJA   := '07'
            ZT3_NOME   := 'FM LOGISTIC'
            ZT3_END    := 'VIA ANHAGUERA, SN KM 26 421'
            ZT3_SOL    := USRRETNAME(RETCODUSR())                                                                                                         
            ZT3_SETOR  := 'Supply Chain'
            ZT3_TES    := '635'
            ZT3_CONDPA := '141'
            ZT3_EMAIL  := USRRETMAIL(RETCODUSR())
            ZT3_PEDIDO := ''                                                                                                         
            ZT3_STATUS := '1'
            ZT3_CODTAB := '079'
            ZT3_TRANSP := '041474'

        MsUnlock()

    // Mudar o status na ZT8
        DbSelectArea('ZT8')
        
        if ZT8->(MsSeek(FWFilial('ZT8') + cNumDoc ))
            RecLock('ZT8', .F.)
               ZT8_STATUS  := '1'      // 1 = Senf gerada
               ZT8_SENF    := cNumSf
            MsUnlock()
        EndIf
        
        DbSelectArea('ZT4')
        While !(cAliasQry)->(EoF())
            
            RecLock('ZT4', .T.)
                ZT4_FILIAL := FWFILIAL('ZT4')
                ZT4_NUMSF  := cNumSf
                ZT4_ITEM   := StrZero(nItem++,3)
                ZT4_COD    := (cAliasQry)->PRODUTO
                ZT4_UM     := 'UN'       // IIF(!INCLUI,POSICIONE("SB1",1,XFILIAL("SB1")+ZT4->ZT4_COD,"B1_UM"),"")
                ZT4_DESC   := (cAliasQry)->DESCRICAO
                ZT4_UM     := (cAliasQry)->UNIDADE
                ZT4_QTDSOL := (cAliasQry)->QUANT
                ZT4_QTDATE := (cAliasQry)->QUANT 
                ZT4_PRCVEN := (cAliasQry)->PRC_UNIT
                ZT4_PRCUNI := (cAliasQry)->PRC_UNIT
                ZT4_VALOR  := (cAliasQry)->PRC_TOTAL 
                ZT4_DTLIB  := DATE()
                ZT4_USLIB  := USRRETNAME(RETCODUSR()) 

                //PARAMETROS//  COD-Produto, Arm Origem, end Origem , Arm destino , End testino, quantidade, lote
                lResp := Tranf_End((cAliasQry)->PRODUTO,(cAliasQry)->ARMAZEM,(cAliasQry)->ENDERECO,(cAliasQry)->ARMAZEM,cEndDest,(cAliasQry)->LOTE,(cAliasQry)->LOTE,(cAliasQry)->QUANT)     
                // tranferir de SEPARACAO p/ EXPEDICAO.                                            
                iF !lResp
                    VTAlert('Saldo no Endereco SEPARACAO é menor que a quantidade contida no Documento','NAO FOI POSSIVEL GERAR SENF',.T.)
                    DisarmTransaction()
                    RETURN lResp
                EndIf 
            MsUnlock()
            (cAliasQry)->(dbSkip())
        EndDo
    End Transaction

    ZT4->(dbCloseArea())
    ZT3->(dbCloseArea())
    ZT8->(dbCloseArea())
    (cAliasQry)->(dbCloseArea())
    
    VTAlert('SENF auxiliar Gerada - Num:'+cNumSf, 'Sucesso!!!',.T.)
    
    fGeraExc(cNumDoc,cNumSf)
   
Else 
    VtAlert('Nenhuma Senf foi gerada','Aviso!!!',.T.)
EndIf

Return

***************************************************************************************************************************************
Static Function Tranf_End(cProduto,cArmOri,cEndOri,cArmDest,cEndDest,cLoteOri,cLoteDest,nQtd)	//Função de transferencia de endereços
***************************************************************************************************************************************
	
    Local _cDoc :=u_SD3_DOC()
    Local lResp := .T.
    Local cCodOri	:= 	cProduto												//	Produto Origem	(Codigo)
	Local cDescrOri	:= 	Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_DESC")    //	Produto Origem	(Descricao)
	Local cUmOri	:=	Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_UM")	    //	Produto Origem	(Unid Medida)
	Local cAlmOri	:= 	cArmOri												    //	Produto Origem	(Almoxarifado)
	Local cCodDest	:=	cProduto												//	Produto Destino	(Codigo)
	Local cDescrDest:=	Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_DESC")	//	Produto Destino	(Descricao)
	Local cUmDest	:=	Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_UM")	    //	Produto Destino	(Unid Medida)
	Local cAlmDest	:=	cArmDest												//	Produto Destino	(Almoxarifado

	Local cNumSerie	:= 	""							                            //	Produto	(Numero de Serie)
	Local cLote		:= 	cLoteOri							                    //	Produto	(Lote)
	Local cSLote	:= 	Space(06)								                //	Produto	(Sub Lote)
	Local cValLote	:= 	ctod('')								                //	Produto	(Validade do Lote)
	Local nPotenc	:= 	0										                //  Potencia
	Local nQtde		:= 	nQtd									                //	Produto	(Quantidade do movimento)
	Local nQtde2	:=	nQtd                                                    //	Produto	(Quantidade do movimento na Segunda Unidade Medida)
	Local cEstorn	:= 	"N"								                        //	Produto	(Se igual a S = Indica estorno)
	Local cSeq      := 	ProxNum()								                //	Produto	(Sequencia utilizada pelo sistema)
	//Local cLoteDest	:=	cLoteDest							                //	Produto	(Lote Destino)
	Local cValLtDest:=	ctod('')								                //  Produto (Validade Destino)

	Local aSepa  := {{_cDoc,dDataBase}}	                                        //Criacao da 1a. linha do array com o documento e data
	
	lmsErroAuto	:= .F.

	aAdd(aSepa,{	cCodOri		,;	                                            //	Produto Origem	(Codigo)
	cDescrOri	,;	                                                            //	Produto Origem	(Descricao)
	cUmOri		,;	                                                            //	Produto Origem	(Unid Medida)
	cAlmOri		,;	                                                            //	Produto Origem	(Almoxarifado)
	cEndOri		,;	                                                            //	Produto Origem	(Endereco)
	cCodDest	,;	                                                            //	Produto Destino	(Codigo)
	cDescrDest	,;	                                                            //	Produto Destino	(Descricao)
	cUmDest		,;	                                                            //	Produto Destino	(Unid Medida)
	cAlmDest	,;	                                                            //	Produto Destino	(Almoxarifado)
	cEndDest	,;	                                                            //	Produto Destino	(Endereco)
	cNumSerie	,;	                                                            //	Produto	(Numero de Serie)
	cLote		,;	                                                            //	Produto	(Lote)
	cSLote		,;	                                                            //	Produto	(Sub Lote)
	cValLote	,;	                                                            //	Produto	(Validade do Lote)
	nPotenc		,;                                                              //	Produto (Potencia)
	nQtde		,;	                                                            //	Produto	(Quantidade do movimento)
	nQtde2		,;	                                                            //	Produto	(Quantidade do movimento na Segunda Unidade Medida)
	cEstorn		,;	                                                            //	Produto	(Se igual a S = Indica estorno)
	cSeq		,;	                                                            //	Produto	(Sequencia)
	cLoteDest	,;	                                                            //	Produto	(Lote Destino)
	cValLtDest	,;                                                              //  Produto (Validade Lote Destino)
	Space(03)   ,;                                                              //  Item Grade
	Space(128)   ,;                                                             //  OBSERVA
	"Transf. entre Enderecos"})	

    /*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	³Chamada da Rotina automatica para gravacao de dados	³
	|de transferencia modelo II - [tabela SD3] 				|
	ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ*/

	If Len(aSepa) > 1
		x_Area  := Alias()
		x_Rec   := Recno()
		x_Ind   := Indexord()

		MsExecAuto({|x,y| mata261(x,y)},aSepa,3)

		DbSelectArea(x_Area)
		DbSetOrder(x_Ind)
		DbGoto(x_Rec)
	EndIf

	/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	³Verifica se houve algum tipo de erro retornado pela	³
	|rotina automatica.										|
	ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ*/

	If  lmsErroAuto
		DLVTAviso('SIGAWMS', '!!!! ERRO DE Transferência !!!!')
         lResp :=.F.
		Return  lResp
		//Endif
	Endif

Return lResp

Static Function fGeraExc(cNumDoc,cNumSf)
 Local cQuery :=''
 Local oFWMsExcel
 Local cArquivo := "\system\senf.xls"

If file(cArquivo)
    fErase(cArquivo)
EndIf

cQuery+= "  SELECT DISTINCT         "
cQuery+= "      ZT4.ZT4_DESC,           "
cQuery+= "      ZT4.ZT4_COD ,           "
cQuery+= "      ZT4.ZT4_NUMSF,          "
cQuery+= "      ZT9.ZT9_CXCOLE,         "
cQuery+= "      ZT9.ZT9_LACRE,          "
cQuery+= "      ZT9.ZT9_QRCODE          "
cQuery+= "  FROM "+ RetSQLName('ZT4') + " ZT4 (NOLOCK)   "
cQuery+= "  INNER JOIN " + RetSQLName('ZT8') + " ZT8 (NOLOCK) ON ZT8.D_E_L_E_T_='' AND  ZT8.ZT8_SENF = ZT4.ZT4_NUMSF "
cQuery+= "  INNER JOIN " + RetSQLName('ZT9') + " ZT9 (NOLOCK) ON ZT9.D_E_L_E_T_='' AND  ZT9.ZT9_DOCAUX = ZT8.ZT8_DOC  and ZT4.ZT4_COD = ZT9.ZT9_CODPRO  "
cQuery+= "  WHERE   ZT4.D_E_L_E_T_=''  AND ZT4.ZT4_NUMSF = '"+ cNumSf + "'"
cQuery+= "  GROUP BY ZT4.ZT4_COD,ZT4.ZT4_DESC,ZT4.ZT4_NUMSF, ZT4.ZT4_QTDATE,ZT4.ZT4_ITEM,ZT9.ZT9_CXCOLE,ZT9.ZT9_LACRE,ZT9.ZT9_QRCODE  "


cQuery := ChangeQuery(cQuery)
dbUseArea(.T.,"TOPCONN",tcGenQry(,,cQuery),"cAliasQry",.F.,.F.)


oFWMsExcel := FwMsExcelEx():New()
     
    oFWMsExcel:AddworkSheet("Senf-Aux") //Não utilizar número junto com sinal de menos. Ex.: 1-
        //Criando a Tabela
        oFWMsExcel:AddTable("Senf-Aux","DOC-AUX: "+cNumDoc +" / SENF: "+cNumSf)
        //Criando Colunas
        oFWMsExcel:AddColumn("Senf-Aux","DOC-AUX: "+cNumDoc +" / SENF: "+cNumSf,"Codigo",1,1) 
        oFWMsExcel:AddColumn("Senf-Aux","DOC-AUX: "+cNumDoc +" / SENF: "+cNumSf,"Descrição",1,1)
        oFWMsExcel:AddColumn("Senf-Aux","DOC-AUX: "+cNumDoc +" / SENF: "+cNumSf,"N° Senf",1,1)
        oFWMsExcel:AddColumn("Senf-Aux","DOC-AUX: "+cNumDoc +" / SENF: "+cNumSf,"Etiqueta QR",1,1)
        oFWMsExcel:AddColumn("Senf-Aux","DOC-AUX: "+cNumDoc +" / SENF: "+cNumSf,"Lacre",1,1)
        oFWMsExcel:AddColumn("Senf-Aux","DOC-AUX: "+cNumDoc +" / SENF: "+cNumSf,"Cx coletiva",1,1)

        //Criando as Linhas
        While !(cAliasQry->(EoF()))
            oFWMsExcel:AddRow("Senf-Aux","DOC-AUX: "+cNumDoc +" / SENF: "+cNumSf,{;
                cAliasQry->ZT4_COD,;
                cAliasQry->ZT4_DESC,;
                cAliasQry->ZT4_NUMSF,;
                cAliasQry->ZT9_QRCODE,;
                cAliasQry->ZT9_LACRE,;
                cAliasQry->ZT9_CXCOLE;
                })
         cAliasQry->(DbSkip())
        EndDo  

    oFWMsExcel:Activate()
    oFWMsExcel:GetXMLFile(cArquivo)
         
    //Abrindo o excel e abrindo o arquivo xml
   oExcel := MsExcel():New()                //Abre uma nova conexão com Excel
   oExcel:WorkBooks:Open(cArquivo)          //Abre uma planilha
   oExcel:SetVisible(.F.)                   //Visualiza a planilha
   fEnvEmail(cArquivo,cNumSf)                 
   oExcel:Destroy()


Return
	
Static Function fEnvEmail(cArquivo,cNumSf)

	Local cCorpo
	Local aAnexos  := {}
    cPara := USRRETMAIL(RETCODUSR())        //'ricky.moraes@gamaitaly.com.br;'
	  

	Private cMailConta	:= NIL
	Private cMailServer	:= NIL 
	Private cMailSenha	:= NIL
	
	AADD(aAnexos,cArquivo)
 
    cAssunto := 'Pick-List Doc-Aux/SENF'
    cCorpo :=  'Segue anexo Lista de Produtos envolvidos na SENF: ' + cNumSf

	GPEMail(cAssunto, cCorpo, cPara,aAnexos )
	 
return
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

// buscar funcao de dados
	_cHTML+=fDadosAniveRH(cFil1)
	_cHTML+=sfMontarRodape()
	

RETURN(_cHTML)
Return 
