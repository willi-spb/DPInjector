unit u_injectFuncs;

interface

uses Classes;

type
  TInjectActions=class(TObject)
    private
     FRegime:integer;
     FSectFlag,FProjFlag,FTagFlag:boolean;
    public
    ///
    constructor Create(aRg:integer);
    destructor Destroy; override;
    ///
    procedure Clearparams;
    ///
    /// <summary>
    ///    Add to DPR-file
    /// </summary>
    function AddToProject(const AFName,ARText:String; DeliChar:Char='|'):boolean;
    /// <summary>
    ///   Add to Interface Implementation Section in aXX.pas file
    /// </summary>
    function AddToSections(const AFName,ARText:String; AInterfaceFlag:boolean):boolean;
    /// <summary>
    ///    Replace Part in Pas-file --
    /// </summary>
    function ReplaceTag(const AFName,ATag,ARText:String; DeliChar:Char='|'):boolean;
    function InsertProjFormData(const AFName,AInfo:String):boolean;
    function IsReplaced:boolean;
    ///
    //// <summary>
     ///    add Resource to DProj aNameEqFilename format->  RESName=/Resource/Reffile.ccc
     /// </summary>
    function ModifyProjResource(const aResFileName,ANameEqFilename:String; const AResType:String='RCDATA'):boolean;
  end;

implementation

uses SysUtils;


{ TInjectActions }

function TInjectActions.AddToProject(const AFName,ARText: String;
  DeliChar:Char='|'): boolean;
var LLIst,LReplList:TStringList;
    LS,LText,LRes:String;
    i,j,k:integer;
    LFlag:boolean;
begin
 Result:=false;
 LFlag:=false;
 LText:=Trim(ARText);
 if LText='' then exit;
 if Ltext[Length(LText)]<>';' then
    LText:=LText+';';
 LLIst:=TStringList.Create;
 LReplList:=TStringList.Create;
 try
   LLIst.LoadFromFile(AFName);
   LReplList.Delimiter:=DeliChar;
   LReplList.StrictDelimiter:=True;
   LReplList.DelimitedText:=LText;
   if LReplList.Count=0 then exit;
   i:=0;
   while i<LReplList.Count do
    begin
      LS:=Trim(LReplList.Strings[i]);
      if (LS='') or (LS=';') then
         LReplList.Delete(i)
      else Inc(i);
    end;
   i:=0;
   while i<LList.Count-1 do
    begin
      LS:=lowercase(Trim(LList.Strings[i]));
      if LS='uses' then
        begin
         LFlag:=true;
       //  Continue;
        end;
      ///
      if LFlag then
        begin
        j:=Pos(';',TrimRight(LList.Strings[i]));
        if j=Length(LList.Strings[i]) then
           begin
             LLIst.Strings[i]:=StringReplace(LList.Strings[i],';',',',[]);
             j:=0;  k:=i+1;
             LS:=TrimRight(LReplList.Strings[LReplList.Count-1]);
             if (LS='') or (LS[Length(LS)]<>';') then
                 LReplList.Strings[LReplList.Count-1]:=LS+';';
             while j<LReplList.Count do
               begin
                 LLIst.Insert(k,'  '+LReplList.Strings[j]);
                 Inc(k);
                 Inc(j);
               end;
             Result:=true;
             break;
           end;
        end;
      ///
      Inc(i);
    end;
    ///
   if Result then
      try
       LList.SaveToFile(AFName);
       FProjFlag:=true;
      except
        Result:=false;
      end;
   ///
  finally
   LList.Free;
   LReplList.Free;
 end;
end;

function TInjectActions.AddToSections(const AFName,ARText: String;
  AInterfaceFlag:boolean): boolean;
var LLIst:TStringList;
    LS,LSect,LText,LRes:String;
    i,j:integer;
    L_inFlag,LFlag:boolean;
begin
 Result:=false;
 LFlag:=false;
 L_inFlag:=false;
 LText:=', '+ARText+';';
 if AInterfaceFlag then
    LSect:='interface'
 else
    LSect:='implementation';

 LLIst:=TStringList.Create;
 try
   LLIst.LoadFromFile(AFName);
   i:=0;
   while i<LList.Count do
    begin
      LS:=Lowercase(Trim(LList.Strings[i]));
      ///
      if LS=LSect then
        begin
         L_inFlag:=true;
         Inc(i);
         Continue;
        end;
      ///
      if (L_inFlag=true) and (Pos('uses',LS)=1) then
         LFlag:=true;
      ///
      if LFlag then
        begin
         j:=Pos(';',LList.Strings[i]);
         if j>1 then
           begin
             LRes:=StringReplace(LList.Strings[i],';',LText,[]);
             LLIst.Strings[i]:=LRes;
             Result:=true;
             L_inFlag:=false;
             break;
           end;
        end;
      ///
      Inc(i);
    end;
   ///
   if Result then
      try 
       LList.SaveToFile(AFName);
       FSectFlag:=true;
      except
        Result:=false;
      end;
   ///
  finally
   LList.Free;
 end;
end;

procedure TInjectActions.Clearparams;
begin
 FSectFlag:=false;
 FProjFlag:=false;
 FTagFlag:=false;
end;

constructor TInjectActions.Create;
begin
  inherited Create;
  FRegime:=arg;
end;

destructor TInjectActions.Destroy;
begin
  inherited;
end;

function TInjectActions.InsertProjFormData(const AFName,
  AInfo: String): boolean;
var LLIst,LReplList:TStringList;
    LS,LS1:String;
    i,j,k:integer;
    LFlag:boolean;
begin
 LLIst:=TStringList.Create;
 LReplList:=TStringList.Create;
 try
   LReplList.Delimiter:=';';
   LReplList.StrictDelimiter:=True;
   LReplList.DelimitedText:=AInfo;
   LLIst.LoadFromFile(AFName);
   LFlag:=false;
   i:=0;  // Count-1   !!
   while i<(LList.Count-1) do
    begin
      LS:=Trim(LList.Strings[i]);
      LS1:=Trim(LList.Strings[i+1]);
      if (Pos('</DCCReference>',LS)=1) and
         ((Pos('<RcItem Include',LS1)=1) or (Pos('<BuildConfiguration Include',LS1)=1)) then
         begin
           k:=LReplList.IndexOfName('FILE');
           if k>=0 then
             begin
              LList.Insert(i+1,'<DCCReference Include="'+LReplList.ValueFromIndex[k]+'">');
              LFlag:=true;
              Inc(i);
             end;
           ///
           k:=LReplList.IndexOfName('FORM');
           if k>=0 then
            begin
              LList.Insert(i+1,'<Form>'+LReplList.ValueFromIndex[k]+'</Form>');
              Inc(i);
            end;
           k:=LReplList.IndexOfName('FORM_TYPE');
           if k>=0 then
            begin
              LList.Insert(i+1,'<FormType>'+LReplList.ValueFromIndex[k]+'</FormType>');
              Inc(i);
            end;
           ///
          if LFlag then
            begin
             LLIst.Insert(i+1,'</DCCReference>');
             Result:=true;
             break;
            end;
         end;
     Inc(i);
    end;
   if Result then
      try
       LList.SaveToFile(AFName);
       FProjFlag:=true;
      except
        Result:=false;
      end;
   ///
  finally
   LList.Free;
   LReplList.Free;
 end;
end;

function TInjectActions.IsReplaced: boolean;
begin
 Result:=(FSectFlag=true) or (FProjFlag=true) or (FTagFlag=true);
end;

{function TInjectActions.ModifyResource(const aResFileName, ANameEqFilename: String;
  const AResType:String): boolean;
var LResType,LResName,LResFile,LResStr,L_Line,L_name,L_File:string;
    LList:TStringlist;
    i,j,k,L_ReplIndex:integer;
begin
  Result:=false;
  L_ReplIndex:=-1;
  if Trim(AResType)='' then LResType:='RCDATA' else LResType:=Trim(AResType);
  LResName:=''; LResFile:='';
  i:=Pos('=',ANameEqFilename);
  if (i>0) and (i<Length(ANameEqFilename)) then
     begin
       LResName:=Copy(ANameEqFilename,1,i-1);
       LResFile:=Copy(ANameEqFilename,i+1,Length(ANameEqFilename)-i);
       LResStr:=StringReplace(LResFile,pathDelim,'',[]); // remove first /
       LResStr:=StringReplace(LResStr,pathDelim,'\\',[rfReplaceAll]);
       LResStr:=LResName+' '+Uppercase(LResType)+' '+'"'+LResStr+'"';
     end;
  Assert((LResName<>'') and (LResFile<>''),'TInjectActions.ModifyResource (line=284) - not resource Name or File!');
  LLIst:=TStringList.Create;
  try
   LList.LoadFromFile(aResFileName);
   i:=0;
   while i<LList.Count do
     begin
       L_Line:=Trim(LList.Strings[i]);
       j:=Pos(' ',L_Line);
       k:=Pos('"',L_Line);
       if (j>1) and (k>1) and (k>j) then
        begin
          L_name:=Copy(L_Line,1,j-1);
          L_File:=Copy(L_Line,k+1,Length(L_Line)-k-1);
          if Uppercase(L_name)=Uppercase(LResName) then
             begin
               L_ReplIndex:=i;
               break;
             end;
        end;
       Inc(i);
     end;
   ///
   if L_ReplIndex<0 then
      LList.Add(LResStr)
   else LList.Strings[L_ReplIndex]:=LResStr;
   LList.SaveToFile(aResFileName);
   Result:=true;
   ///
  finally
    LList.Free;
  end;
end;
}
function TInjectActions.ModifyProjResource(const aResFileName, ANameEqFilename: String;
  const AResType:String): boolean;
var LResType,LResName,LResFile,LResStr,L_Line,L_name,L_File:string;
    LList:TStringlist;
    i,j,L_ReplIndex:integer;
    LNewFlag:boolean;
begin
  Result:=false; LNewFlag:=true;
  L_ReplIndex:=-1;
  if Trim(AResType)='' then LResType:='RCDATA' else LResType:=Trim(AResType);
  LResName:=''; LResFile:='';
  i:=Pos('=',ANameEqFilename);
  if (i>0) and (i<Length(ANameEqFilename)) then
     begin
       LResName:=Copy(ANameEqFilename,1,i-1);
       LResFile:=Copy(ANameEqFilename,i+1,Length(ANameEqFilename)-i);
       LResStr:=StringReplace(LResFile,pathDelim,'',[]); // remove first /
       LResStr:=StringReplace(LResStr,pathDelim,'\',[rfReplaceAll]);
       LResStr:='<RcItem Include="'+LResStr+'">';
     end;
  Assert((LResName<>'') and (LResFile<>''),'TInjectActions.ModifyResource - not resource Name or File!');
  LLIst:=TStringList.Create;
  try
   LList.LoadFromFile(aResFileName);
   i:=0; j:=0;
   while i<LList.Count do
     begin
       L_Line:=Trim(LList.Strings[i]);
       if Uppercase(L_Line)=Uppercase(LResStr) then
             begin
               L_ReplIndex:=i;
               LNewFlag:=false;
               break;
             end;
       Inc(i);
     end;
   if L_ReplIndex<0 then
     begin
       i:=0;
       while i<LList.Count do
        begin
          j:=Pos('<BuildConfiguration',LList.Strings[i]);
          if j>0 then
            begin
              L_ReplIndex:=i;
              Break;
            end;
          Inc(i);
        end;
     end;
   ///
   if L_ReplIndex>0 then
     begin
      if LNewFlag=false then
        begin
          for j:=0 to 4 do
            LList.Delete(L_ReplIndex);
        end;
      LList.Insert(L_ReplIndex,'</RcItem>');
      LList.Insert(L_ReplIndex,'<ResourceId>'+LResName+'</ResourceId>');
      LList.Insert(L_ReplIndex,'<ResourceType>'+UpperCase(LResType)+'</ResourceType>');
      LList.Insert(L_ReplIndex,'<ContainerId>ResourceItem</ContainerId>');
      LList.Insert(L_ReplIndex,LResStr);
   ///
      LList.SaveToFile(aResFileName);
      Result:=true;
     end;
   ///
  finally
    LList.Free;
  end;
end;


function TInjectActions.ReplaceTag(const AFName,ATag,ARText:String;DeliChar:Char='|'):boolean;
var LLIst,LReplList:TStringList;
    LS,LSS,LSS2,Ltag,LText:String;
    i,j,k:integer;
    LFlag:boolean;
    L_SelfAddFlag:boolean;
    L_ReplDeleteCount:integer;
    ///
    /// TAG_COUNT=<L_RepltagCount> - if parameter not found - Replace One tag in List!  100000 - replace all
    L_RepltagNum,L_RepltagCount:integer;
    ///
begin
 Result:=false;
 LFlag:=false;
 Ltag:=Atag;
 L_ReplDeleteCount:=0;
 ///
 L_RepltagNum:=0;
 L_RepltagCount:=-1;
 ///
 LLIst:=TStringList.Create;
 LReplList:=TStringList.Create;
 try
   LReplList.Delimiter:=DeliChar;
   LReplList.StrictDelimiter:=True;
   LReplList.DelimitedText:=ARText;
   ///  Add Self Tag information  - replace SELF to aTag String
   i:=LReplList.IndexOf('SELF');
   if i>=0 then
    begin
      L_SelfAddFlag:=true;
      LReplList.Strings[i]:=ATag;
    end;
   ///
   i:=LReplList.IndexOfName('DEL_LINES');
   if i>=0 then
      begin
        TryStrToInt(LReplList.ValueFromIndex[i],L_ReplDeleteCount);
        LReplList.Delete(i);
      end;
   i:=LReplList.IndexOfName('TAG_COUNT');
   if i>=0 then
      begin
        TryStrToInt(LReplList.ValueFromIndex[i],L_RepltagCount);
        LReplList.Delete(i);
      end;
   ///
   LLIst.LoadFromFile(AFName);
   i:=0;  // Count-1   !!
   while i<(LList.Count-1) do
    begin
      LS:=Trim(LList.Strings[i]);
      if LS=Ltag then
        begin
         // LList.Strings[i]:='';
           if L_ReplDeleteCount=-1 then
               begin /// Delete lines to next SignLines
                 j:=i;
                 while j<LList.Count-1 do
                   begin
                     LSS:=Lowercase(Trim(LList.Strings[j]));
                     LSS2:=Lowercase(Trim(LList.Strings[j+1]));
                     if (Pos('end;',LSS)=1) and ((LSS2='') or (Pos('end.',LSS2)=1)) then
                      begin
                        L_ReplDeleteCount:=j-i+1;
                        break; // !
                      end;
                     Inc(j);
                   end;
               end;
          /// delete setting lines
          if L_ReplDeleteCount>0 then
           begin
             for k:=1 to L_ReplDeleteCount do
                 LLIst.Delete(i);
           end;
          ///
          j:=LReplList.Count-1;
          while J>=0 do
           begin
              LList.Insert(i,LReplList.Strings[j]);
              Dec(j);
              Result:=true;
           end;
         Inc(L_RepltagNum);
         if (L_RepltagCount<=0) or (L_RepltagNum>=L_ReplTagCount) then
             break;
        end;
      Inc(i);
    end;
    ///
   if Result then
    try
       LList.SaveToFile(AFName);
       FTagFlag:=true;
      except
        Result:=false;
      end;
   ///
  finally
   LList.Free;
   LReplList.Free;
 end;

end;

end.
