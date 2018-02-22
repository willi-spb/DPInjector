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
    function AddToProject(const AFName,ARText:String; inIncludeOpt:boolean=false):boolean;
    function AddToSections(const AFName,ARText:String; AInterfaceFlag:boolean):boolean;
    function ReplaceTag(const AFName,ATag,ARText:String; DeliChar:Char='|'):boolean;
    function InsertProjFormData(const AFName,AInfo:String):boolean;
    function IsReplaced:boolean;
  end;

implementation

uses SysUtils;


{ TInjectActions }

function TInjectActions.AddToProject(const AFName,ARText: String;
  inIncludeOpt: boolean): boolean;
var LLIst:TStringList;
    LS,LText,LRes:String;
    i,j:integer;
    LFlag:boolean;
begin
 Result:=false;
 LFlag:=false;
 if inIncludeOpt=false then
    LText:=ARText+' in '''+ARText+'.pas'';'
 else LText:=ARText+';';
 LLIst:=TStringList.Create;
 try
   LLIst.LoadFromFile(AFName);
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
        j:=Pos(';',LList.Strings[i]);
        if j=Length(LList.Strings[i]) then
           begin
             LLIst.Strings[i]:=StringReplace(LList.Strings[i],';',',',[]);
             LLIst.Insert(i+1,'  '+LText);
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

function TInjectActions.ReplaceTag(const AFName,ATag,ARText:String;DeliChar:Char='|'):boolean;
var LLIst,LReplList:TStringList;
    LS,LSS,LSS2,Ltag,LText:String;
    i,j,k:integer;
    LFlag:boolean;
    L_SelfAddFlag:boolean;
    L_ReplDeleteCount:integer;
begin
 Result:=false;
 LFlag:=false;
 Ltag:=Atag;
 L_ReplDeleteCount:=0;
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
