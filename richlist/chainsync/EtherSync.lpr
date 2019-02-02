program EtherSync;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, CustApp, Contnrs,
  { you can add units after this }
  StrUtils, Math, DateUtils, IniFiles, SyncObjs,
  // xml related units
  DOM, XMLRead, XMLUtils,
  // HTTP
  httpsend, ssl_openssl,
  // JSON
  fpjson, jsonparser,
  // MYSQL
  db, sqldb, mysql57conn;

type

  { TNotifyObject }

  TNotifyObject = class
  private
    FURL: string;
    FName: string;
    FAType: string;
    FLimit: Integer;
    FAddress: string;
  public
    property URL: string read FURL write FURL;
    property Name: string read FName write FName;
    property AType: string read FAType write FAType;
    property Limit: Integer read FLimit write FLimit;
    property Address: string read FAddress write FAddress;
  end;

  { TEtherSync }

  TEtherSync = class(TCustomApplication)
  private
    FSQLConn: TSQLConnector;
    FSQLQuery: TSQLQuery;
    FSQLTrans: TSQLTransaction;
    FIniFileName: string;
    FSyncSettings: TIniFile;
    FNotifyList: TFPObjectHashTable;
    procedure ConnectToMysqlDB;
    procedure DisconnectFromMysqlSB;
    procedure AddTransactionToMysqlDB(const aRecord: TJSONData;
                                      const Timestamp: Double);
    procedure AddToRichListToMysqlDB(const aRecord: TJSONData;
                                     const Timestamp: Double);
    procedure AddFromRichListToMysqlDB(const aRecord: TJSONData;
                                       const Timestamp: Double);
    procedure UpdateToRichListInMysqlDB(const address: string;
                                        const Timestamp: Double);
    procedure UpdateFromRichListInMysqlDB(const address: string;
                                          const Timestamp: Double);
    function FindAddressInMysqlDB(const address: string): Boolean;
    procedure UpdateAddressBalance(const address: string);
    function GetCurrentBlockNumber: Int64;
    procedure UpdateTopHundredAddresses;
    procedure SyncEtherBlockchain;
    procedure ShowCurrentBlock;
    procedure ParseNotifyList;
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;


function HexToDecimal(S: string): Double;
var
  I: Integer;
  Len: Integer;
  Base: Integer;
begin
  Result := 0;

  if Pos('0x', S) = 1 then
    S := Copy(S, 3, Length(S));

  // final length
  Len := Length(S);

  for I := 1 to Len do
  begin
    Base := StrToInt('$' + S[I]);
    Result := Result + (Base * power(16, Len - I));
  end;
end;

{ TEtherSync }

procedure TEtherSync.ConnectToMysqlDB;
begin
  FSQLConn := TSQLConnector.Create(nil);
  FSQLConn.ConnectorType := FSyncSettings.ReadString('database', 'ConnectorType', '');
  FSQLConn.HostName  := FSyncSettings.ReadString('database', 'HostName', '');
  FSQLConn.DatabaseName := FSyncSettings.ReadString('database', 'DatabaseName', '');
  FSQLConn.UserName := FSyncSettings.ReadString('database', 'UserName', '');
  FSQLConn.Password := FSyncSettings.ReadString('database', 'Password', '');

  FSQLTrans := TSQLTransaction.Create(nil);
  FSQLConn.Transaction := FSQLTrans;

  FSQLQuery := TSQLQuery.Create(nil);
  FSQLQuery.Transaction := FSQLTrans;
  FSQLQuery.DataBase := FSQLConn;
  FSQLConn.Open;
end;

procedure TEtherSync.DisconnectFromMysqlSB;
begin
  FSQLConn.Close(False);
  FreeAndNil(FSQLQuery);
  FreeAndNil(FSQLTrans);
  FreeAndNil(FSQLConn);
end;

function TEtherSync.FindAddressInMysqlDB(const address: string): Boolean;
begin
  FSQLQuery.SQL.Clear;
  FSQLQuery.SQL.Add('SELECT value FROM richlist where address = :address');
  FSQLQuery.ParamByName('address').AsString := address;
  FSQLQuery.Open;
  try
    FSQLQuery.First;
    Result := not FSQLQuery.EOF;
  finally
    FSQLQuery.Close;
  end;
end;

procedure TEtherSync.AddToRichListToMysqlDB(const aRecord: TJSONData; const Timestamp: Double);
var
  BlockNumber: Int64;
begin
  BlockNumber := Trunc(HexToDecimal(aRecord.FindPath('blockNumber').AsString));

  FSQLQuery.SQL.Clear;
  FSQLQuery.SQL.Add('INSERT INTO richlist (address,block,firstIn,lastIn,firstOut,lastOut,numIn,numOut,value) VALUES (:address,:block,:firstIn,:lastIn,:firstOut,:lastOut,:numIn,:numOut,0)');
  FSQLQuery.ParamByName('address').AsString := aRecord.FindPath('to').AsString;
  FSQLQuery.ParamByName('firstIn').AsDateTime := UnixToDateTime(Trunc(Timestamp));
  FSQLQuery.ParamByName('lastIn').AsDateTime := UnixToDateTime(Trunc(Timestamp));
  FSQLQuery.ParamByName('block').AsLargeInt := BlockNumber;
  FSQLQuery.ParamByName('firstOut').Value := Null;
  FSQLQuery.ParamByName('lastOut').Value := Null;
  FSQLQuery.ParamByName('numIn').AsInteger := 1;
  FSQLQuery.ParamByName('numOut').AsInteger := 0;
  FSQLQuery.ExecSQL;
end;

procedure TEtherSync.AddFromRichListToMysqlDB(const aRecord: TJSONData; const Timestamp: Double);
var
  BlockNumber: Int64;
begin
  BlockNumber := Trunc(HexToDecimal(aRecord.FindPath('blockNumber').AsString));

  FSQLQuery.SQL.Clear;
  FSQLQuery.SQL.Add('INSERT INTO richlist (address,block,firstIn,lastIn,firstOut,lastOut,numIn,numOut,value) VALUES (:address,:block,:firstIn,:lastIn,:firstOut,:lastOut,:numIn,:numOut,0)');
  FSQLQuery.ParamByName('address').AsString := aRecord.FindPath('from').AsString;
  FSQLQuery.ParamByName('firstOut').AsDateTime := UnixToDateTime(Trunc(Timestamp));
  FSQLQuery.ParamByName('lastOut').AsDateTime := UnixToDateTime(Trunc(Timestamp));
  FSQLQuery.ParamByName('block').AsLargeInt := BlockNumber;
  FSQLQuery.ParamByName('firstIn').Value := Null;
  FSQLQuery.ParamByName('lastIn').Value := Null;
  FSQLQuery.ParamByName('numIn').AsInteger := 0;
  FSQLQuery.ParamByName('numOut').AsInteger := 1;
  FSQLQuery.ExecSQL;
end;

procedure TEtherSync.AddTransactionToMysqlDB(const aRecord: TJSONData;
                                             const Timestamp: Double);
var
  HTTP: THTTPSend;
  Value: Double;
  BlockNumber: Int64;
  ToAddress: TJSONData;
  FromAddress: TJSONData;
  Parameters: TJSONObject;
  NotifyObject: TNotifyObject;
  ParametersAsStream: TStringStream;
begin
  BlockNumber := Trunc(HexToDecimal(aRecord.FindPath('blockNumber').AsString));
  FromAddress := aRecord.FindPath('from');
  ToAddress := aRecord.FindPath('to');

  FSQLQuery.SQL.Clear;
  FSQLQuery.SQL.Add('INSERT INTO transactions (hash,txhash, block,timestamp,fromaddr,toaddr,value) VALUES (:hash,:txhash,:block,:timestamp,:fromaddr,:toaddr,:value)');
  FSQLQuery.ParamByName('hash').AsString := aRecord.FindPath('blockHash').AsString;
  FSQLQuery.ParamByName('txhash').AsString := aRecord.FindPath('hash').AsString;
  FSQLQuery.ParamByName('block').AsLargeInt := BlockNumber;
  FSQLQuery.ParamByName('timestamp').AsDateTime := UnixToDateTime(Trunc(Timestamp));
  FSQLQuery.ParamByName('value').AsFloat := HexToDecimal(aRecord.FindPath('value').AsString);
  case FromAddress.IsNull of
    False: FSQLQuery.ParamByName('fromaddr').AsString := aRecord.FindPath('from').AsString;
    True: FSQLQuery.ParamByName('fromaddr').Value:= Null;
  end;
  case ToAddress.IsNull of
    False: FSQLQuery.ParamByName('toaddr').AsString := aRecord.FindPath('to').AsString;
    True: FSQLQuery.ParamByName('toaddr').Value:= Null;
  end;
  FSQLQuery.ExecSQL;

  // update the addresses balance
  if not ToAddress.IsNull then
    UpdateAddressBalance(aRecord.FindPath('to').AsString);
  if not FromAddress.IsNull then
    UpdateAddressBalance(aRecord.FindPath('from').AsString);

  // check for suspicious transactions
  try
    if FNotifyList.Count > 0 then
    begin
      if (not ToAddress.IsNull) and (not FromAddress.IsNull) then
      begin
        // check the recipient address first
        NotifyObject := TNotifyObject(FNotifyList.Items[AnsiUpperCase(ToAddress.AsString)]);

        if NotifyObject <> nil then
        begin
          Value := (HexToDecimal(aRecord.FindPath('value').AsString) / Power(10,18));

          if Value > NotifyObject.Limit then
          begin
            HTTP := THTTPSend.Create;
            try
              Parameters := TJSONObject.Create;
              try
                Parameters.Add('content', Format('%f ETHO sent from **%s** to **%s**', [Value, FromAddress.AsString, NotifyObject.Name]));

                ParametersAsStream := TStringStream.Create(Parameters.AsJson);
                HTTP.Document.CopyFrom(ParametersAsStream, 0);
                HTTP.MimeType := 'application/json';

                HTTP.HTTPMethod('POST', NotifyObject.URL);
              finally
                Parameters.Free;
              end;
            finally
              HTTP.Free;
            end;
          end;
        end;

        if (not ToAddress.IsNull) and (not FromAddress.IsNull) then
        begin
          // check the sender address second
          NotifyObject := TNotifyObject(FNotifyList.Items[AnsiUpperCase(FromAddress.AsString)]);

          if NotifyObject <> nil then
          begin
            Value := (HexToDecimal(aRecord.FindPath('value').AsString) / Power(10,18));

            if Value > NotifyObject.Limit then
            begin
              HTTP := THTTPSend.Create;
              try
                Parameters := TJSONObject.Create;
                try
                  Parameters.Add('content', Format('%f ETHO sent from **%s** to **%s**', [Value, NotifyObject.Name, ToAddress.AsString]));

                  ParametersAsStream := TStringStream.Create(Parameters.AsJson);
                  HTTP.Document.CopyFrom(ParametersAsStream, 0);
                  HTTP.MimeType := 'application/json';

                  HTTP.HTTPMethod('POST', NotifyObject.URL);
                finally
                  Parameters.Free;
                end;
              finally
                HTTP.Free;
              end;
            end;
          end;
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      WriteLn(Format('Error checking for suspicious transactions %s', [E.Message]));
    end;
  end;
end;

procedure TEtherSync.UpdateToRichListInMysqlDB(const address: string; const Timestamp: Double);
begin
  FSQLQuery.SQL.Clear;
  FSQLQuery.SQL.Add('UPDATE richlist SET numIn = numIn + 1, lastIn = :lastIn, firstIn = if(firstIn is null, :firstIn, firstIn) WHERE address = :address');
  FSQLQuery.ParamByName('firstIn').AsDateTime := UnixToDateTime(Trunc(Timestamp));
  FSQLQuery.ParamByName('lastIn').AsDateTime := UnixToDateTime(Trunc(Timestamp));
  FSQLQuery.ParamByName('address').AsString := address;
  FSQLQuery.ExecSQL;
end;

procedure TEtherSync.UpdateFromRichListInMysqlDB(const address: string; const Timestamp: Double);
begin
  FSQLQuery.SQL.Clear;
  FSQLQuery.SQL.Add('UPDATE richlist SET numOut = numOut + 1, lastOut = :lastOut, firstOut = if(firstOut is null, :firstOut, firstOut) WHERE address = :address');
  FSQLQuery.ParamByName('firstOut').AsDateTime := UnixToDateTime(Trunc(Timestamp));
  FSQLQuery.ParamByName('lastOut').AsDateTime := UnixToDateTime(Trunc(Timestamp));
  FSQLQuery.ParamByName('address').AsString := address;
  FSQLQuery.ExecSQL;
end;

procedure TEtherSync.UpdateAddressBalance(const address: string);
var
  HTTP: THTTPSend;
  Value: Double;
  OldVal: Double;
  Options: TJSONArray;
  AResult: TMemoryStream;
  JSONData: TJSONData;
  JSONParser: TJSONParser;
  Parameters: TJSONObject;
  ParametersAsStream: TStringStream;
begin
  Parameters := TJSONObject.Create;
  try
    AResult := TMemoryStream.Create;
    try
      Options := TJSONArray.Create;
      Options.Add(address);
      Options.Add('latest');

      Parameters.Add('jsonrpc', '2.0');
      Parameters.Add('method', 'eth_getBalance');
      Parameters.Add('params', Options);
      Parameters.Add('id', 1);

      HTTP := THTTPSend.Create;
      try
        ParametersAsStream := TStringStream.Create(Parameters.AsJson);
        HTTP.Document.CopyFrom(ParametersAsStream, 0);
        HTTP.MimeType := 'application/json';

        if HTTP.HTTPMethod('POST', FSyncSettings.ReadString('rpc', 'url', '')) then
        begin
          AResult.Size := 0;
          AResult.Seek(0, soFromBeginning);
          AResult.CopyFrom(HTTP.Document, 0);
          AResult.Seek(0, soFromBeginning);
        end
        else
          raise Exception.CreateFmt('No response for address %s', [address]);

        JSONParser := TJSONParser.Create(AResult);
        try
          JSONData := JSONParser.Parse;
          try
            // get the data count
            Value := HexToDecimal(JSONData.FindPath('result').AsString);

            FSQLQuery.SQL.Clear;
            FSQLQuery.SQL.Add('SELECT value from richlist WHERE address = :address');
            FSQLQuery.ParamByName('address').AsString := address;
            FSQLQuery.Open;
            try
              FSQLQuery.First;
              OldVal := 0;

              if not FSQLQuery.EOF then
              begin
                case FSQLQuery.FieldByName('value').IsNull of
                  False: OldVal := FSQLQuery.FieldByName('value').AsFloat;
                  True: OldVal := 0;
                end;
              end;
            finally
              FSQLQuery.Close;
            end;

            if Abs(OldVal - Value) > 10000000000 then
            begin
              FSQLQuery.SQL.Clear;
              FSQLQuery.SQL.Add('UPDATE richlist SET value = :value, needupdate = 0, updatecount = updatecount + 1 WHERE address = :address');
              FSQLQuery.ParamByName('address').AsString := address;
              FSQLQuery.ParamByName('value').AsFloat := Value;
              FSQLQuery.ExecSQL;
            end
            else
            begin
              FSQLQuery.SQL.Clear;
              FSQLQuery.SQL.Add('UPDATE richlist SET value = :value, needupdate = 0 WHERE address = :address');
              FSQLQuery.ParamByName('address').AsString := address;
              FSQLQuery.ParamByName('value').AsFloat := Value;
              FSQLQuery.ExecSQL;
            end;
          finally
            JSONData.Free;
          end;
        finally
          JSONParser.Free;
        end;
      finally
        HTTP.Free;
      end;
    finally
      AResult.Free;
    end;
  finally
    Parameters.Free;
  end;
end;

procedure TEtherSync.UpdateTopHundredAddresses;
var
  I: Integer;
  AddressList: TStringList;
begin
  FSQLTrans.StartTransaction;
  try
    FSQLQuery.SQL.Clear;
    FSQLQuery.SQL.Add('UPDATE richlist SET needupdate = needupdate + 1');
    FSQLQuery.ExecSQL;

    AddressList := TStringList.Create;
    try
      // do the top 100 by change
      FSQLQuery.SQL.Clear;
      FSQLQuery.SQL.Add('SELECT address FROM richlist ORDER BY updatecount DESC LIMIT 500');
      FSQLQuery.Open;
      try
        FSQLQuery.First;

        while not FSQLQuery.EOF do
        begin
          AddressList.Add(FSQLQuery.FieldByName('address').AsString);
          FSQLQuery.Next;
        end;
      finally
        FSQLQuery.Close;
      end;

      // update the actuall balances
      for I := 0 to AddressList.Count - 1 do
        UpdateAddressBalance(AddressList[I]);

      AddressList.Clear;
      // do the next 100 in line
      FSQLQuery.SQL.Clear;
      FSQLQuery.SQL.Add('SELECT address FROM richlist ORDER BY needupdate DESC LIMIT 100');
      FSQLQuery.Open;
      try
        FSQLQuery.First;

        while not FSQLQuery.EOF do
        begin
          AddressList.Add(FSQLQuery.FieldByName('address').AsString);
          FSQLQuery.Next;
        end;
      finally
        FSQLQuery.Close;
      end;

      // update the actuall balances
      for I := 0 to AddressList.Count - 1 do
        UpdateAddressBalance(AddressList[I]);
    finally
      AddressList.Free;
    end;

    // commit changes
    FSQLTrans.Commit;
  except
    on E: Exception do
    begin
      WriteLn(Format('TEtherSync.UpdateTopHundredAddresses error: %s', [E.Message]));
      FSQLTrans.Rollback;
      Halt;
    end;
  end;
end;

function TEtherSync.GetCurrentBlockNumber: Int64;
var
  HTTP: THTTPSend;
  AResult: TMemoryStream;
  JSONData: TJSONData;
  JSONParser: TJSONParser;
  Parameters: TJSONObject;
  ParametersAsStream: TStringStream;
begin
  Parameters := TJSONObject.Create;
  try
    AResult := TMemoryStream.Create;
    try
      Parameters.Add('jsonrpc', '2.0');
      Parameters.Add('method', 'eth_blockNumber');
      Parameters.Add('id', 1);

      HTTP := THTTPSend.Create;
      try
        ParametersAsStream := TStringStream.Create(Parameters.AsJson);
        HTTP.Document.CopyFrom(ParametersAsStream, 0);
        HTTP.MimeType := 'application/json';

        if HTTP.HTTPMethod('POST', FSyncSettings.ReadString('rpc', 'url', '')) then
        begin
          AResult.Size := 0;
          AResult.Seek(0, soFromBeginning);
          AResult.CopyFrom(HTTP.Document, 0);
          AResult.Seek(0, soFromBeginning);
        end
        else
          raise Exception.Create('No response for eth_blockNumber');

        JSONParser := TJSONParser.Create(AResult);
        try
          JSONData := JSONParser.Parse;
          try
            // get the data count
            Result := Trunc(HexToDecimal(JSONData.FindPath('result').AsString));
          finally
            JSONData.Free;
          end;
        finally
          JSONParser.Free;
        end;
      finally
        HTTP.Free;
      end;
    finally
      AResult.Free;
    end;
  finally
    Parameters.Free;
  end;
end;

procedure TEtherSync.SyncEtherBlockchain;
var
  I: Integer;
  HTTP: THTTPSend;
  Options: TJSONArray;
  AResult: TMemoryStream;
  BlockNum: Int64;
  NumTries: Integer;
  JSONData: TJSONData;
  AnAdress: TJSONData;
  Timestamp: Double;
  Processed: Boolean;
  ArrayItem: TJSONData;
  JSONArray: TJSONArray;
  JSONParser: TJSONParser;
  Parameters: TJSONObject;
  ResultData: TJSONObject;
  CurrentBlockNum: Int64;
  ParametersAsStream: TStringStream;
begin
  BlockNum := FSyncSettings.ReadInt64('blockchain', 'lastblock', 1);

  AResult := TMemoryStream.Create;
  try
    ConnectToMysqlDB;
    try
      if not FSQLConn.Connected then
      begin
        writeLn('Could not connect to database. Exiting!');
        Exit;
      end;

      HTTP := THTTPSend.Create;
      try
        while True do
        begin
          CurrentBlockNum := GetCurrentBlockNumber;

          while BlockNum < CurrentBlockNum do
          begin
            Processed := False;
            NumTries := 0;

            while (Processed = False) and (NumTries < 5) do
            begin
              WriteLn(Format('Processing block %d', [BlockNum]));
              try
                // clear the buffers
                HTTP.Document.Clear;
                HTTP.Headers.Clear;
                AResult.Clear;

                Parameters := TJSONObject.Create;
                try
                  // fill opts
                  Options := TJSONArray.Create;
                  Options.Add('0x' + IntToHex(BlockNum, 0));
                  Options.Add(True);

                  // fill params
                  Parameters.Add('jsonrpc', '2.0');
                  Parameters.Add('method', 'eth_getBlockByNumber');
                  Parameters.Add('params', Options);
                  Parameters.Add('id', 1);

                  ParametersAsStream := TStringStream.Create(Parameters.AsJson);
                  HTTP.Document.CopyFrom(ParametersAsStream, 0);
                  HTTP.MimeType := 'application/json';
                finally
                  Parameters.Free;
                end;

                if HTTP.HTTPMethod('POST', FSyncSettings.ReadString('rpc', 'url', '')) then
                begin
                  AResult.Size := 0;
                  AResult.Seek(0, soFromBeginning);
                  AResult.CopyFrom(HTTP.Document, 0);
                  AResult.Seek(0, soFromBeginning);
                end
                else
                  raise Exception.CreateFmt('No response for block %d', [BlockNum]);

                JSONParser := TJSONParser.Create(AResult);
                try
                  JSONData := JSONParser.Parse;
                  try
                    // get the data count
                    ResultData := TJSONObject(JSONData.FindPath('result'));

                    if ResultData <> nil then
                    begin
                      Timestamp := HexToDecimal(ResultData.FindPath('timestamp').AsString);
                      JSONArray := TJSONArray(ResultData.FindPath('transactions'));

                      for I := 0 to JSONArray.Count - 1 do
                      begin
                        FSQLTrans.StartTransaction;

                        ArrayItem := JSONArray.Items[I];
                        // first the recipient address
                        AnAdress := ArrayItem.FindPath('to');

                        if not AnAdress.IsNull then
                        begin
                          // search the richlist for the address
                          if FindAddressInMysqlDB(AnAdress.AsString) then
                            UpdateToRichListInMysqlDB(AnAdress.AsString, Timestamp)
                          else
                            AddToRichListToMysqlDB(ArrayItem, Timestamp);
                        end;

                        // second the sender address
                        AnAdress := ArrayItem.FindPath('from');

                        if not AnAdress.IsNull then
                        begin
                          // search the richlist for the address
                          if FindAddressInMysqlDB(AnAdress.AsString) then
                            UpdateFromRichListInMysqlDB(AnAdress.AsString, Timestamp)
                          else
                            AddFromRichListToMysqlDB(ArrayItem, Timestamp);
                        end;

                        // add the Transaction and balance to the DB
                        AddTransactionToMysqlDB(ArrayItem, Timestamp);
                        // commit the work
                        FSQLTrans.Commit;
                      end;
                    end;
                  finally
                    FreeAndNil(JSONData);
                  end;
                finally
                  FreeAndNil(JSONParser);
                end;

                // block is processed
                Processed := True;
              except
                on E: Exception do
                begin
                  WriteLn(Format('Error syncing the blockchain %s', [E.Message]));
                  Inc(NumTries);
                  Sleep(5000);
                end;
              end;
            end;

            if not Processed then
            begin
              WriteLn(Format('To many tries for block %d', [BlockNum]));
              Exit;
            end;

            // write the last processed block to the ini file and increase it
            FSyncSettings.WriteInt64('blockchain', 'lastblock', BlockNum);
            Inc(BlockNum);
          end;

          // check 100 addresses
          UpdateTopHundredAddresses;

          // sleep for 10 seconds
          Sleep(5000);
        end;
      finally
        HTTP.Free;
      end;
    finally
      DisconnectFromMysqlSB;
    end;
  finally
    AResult.Free;
  end;
end;

procedure TEtherSync.ParseNotifyList;
var
  Doc: TXMLDocument;
  Address: string;
  NotifyNode: TDOMNode;
  NotifyObject: TNotifyObject;
begin
  Doc := nil;
  try
    if FileExists(ExtractFilePath(ParamStr(0)) + 'notify.xml') then
    begin
      // Read in xml file from disk
      ReadXMLFile(Doc, ExtractFilePath(ParamStr(0)) + 'notify.xml');
      NotifyNode := Doc.DocumentElement.FirstChild;

      while Assigned(NotifyNode) do
      begin
        NotifyObject := TNotifyObject.Create;
        Address := NotifyNode.FindNode('Address').FirstChild.NodeValue;

        NotifyObject.URL := NotifyNode.FindNode('URL').FirstChild.NodeValue;
        NotifyObject.Name := NotifyNode.FindNode('Name').FirstChild.NodeValue;
        NotifyObject.AType := NotifyNode.FindNode('Type').FirstChild.NodeValue;
        NotifyObject.Limit := StrToIntDef(NotifyNode.FindNode('Limit').FirstChild.NodeValue, -1);
        FNotifyList.Add(Address, NotifyObject);

        NotifyNode := NotifyNode.NextSibling;
      end;
    end;
  finally
    FreeAndNil(Doc)
  end;
end;

procedure TEtherSync.DoRun;
//var
//  ErrorMsg: String;
begin
  // quick check parameters
  //ErrorMsg := CheckOptions('', ['help','currBlock']);
  //if ErrorMsg<>'' then begin
  //  ShowException(Exception.Create(ErrorMsg));
  //  Terminate;
  //  Exit;
  //end;

  // parse parameters
  if HasOption('h', 'help') then
  begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('currBlock') then
  begin
    ShowCurrentBlock;
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('iniFile') then
    FIniFileName := GetOptionValue('iniFile')
  else
    FIniFileName := ExtractFilePath(ParamStr(0)) + 'settings.ini';

  FSyncSettings := TIniFile.Create(FIniFileName);
  ParseNotifyList;

  { add your program here }
  SyncEtherBlockchain;

  // stop program loop
  Terminate;
end;

constructor TEtherSync.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;

  FNotifyList := TFPObjectHashTable.Create(True);
end;

destructor TEtherSync.Destroy;
begin
  FreeAndNil(FSyncSettings);
  FreeAndNil(FNotifyList);

  inherited Destroy;
end;

procedure TEtherSync.ShowCurrentBlock;
begin
  writeln(FSyncSettings.ReadString('blockchain', 'lastblock', ''));
end;

procedure TEtherSync.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ', ExeName, ' -h');
  writeln('');
  writeln('-currBlock: Write the current block that syning is on');
  writeln('-stop: stops the application');
  writeln('');
end;

var
  Application: TEtherSync;
begin
  Application:=TEtherSync.Create(nil);
  Application.Run;
  Application.Free;
end.

