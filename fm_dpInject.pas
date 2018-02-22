unit fm_dpInject;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, Data.DB, Vcl.Grids, Vcl.ValEdit, Vcl.DBGrids, Vcl.ExtCtrls,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.ToolWin, Vcl.ActnMan,
  Vcl.ActnCtrls, Vcl.ActnList, Vcl.StdActns, System.Actions,
  Vcl.PlatformDefaultStyleActnCtrls, System.ImageList, Vcl.ImgList,
  FireDAC.Stan.StorageXML, Vcl.StdCtrls, Vcl.Buttons, Vcl.DBCtrls, Vcl.ComCtrls;

type
  TDPForm = class(TForm)
    FDMemT: TFDMemTable;
    FDMemTID: TIntegerField;
    FDMemTRCODE: TIntegerField;
    FDMemTFILENAME: TWideStringField;
    FDMemTADD_INFO: TWideStringField;
    FDMemTINTEXT: TWideStringField;
    FDMemTSIGN: TIntegerField;
    DST: TDataSource;
    ImageList1: TImageList;
    ActionManager1: TActionManager;
    FileOpen1: TFileOpen;
    FileSaveAs1: TFileSaveAs;
    actRenameGroup: TAction;
    DBGrid1: TDBGrid;
    ActionToolBar2: TActionToolBar;
    FDStanStorageXMLLink1: TFDStanStorageXMLLink;
    FDMemTTAGNAME: TStringField;
    pnlBottom: TPanel;
    VLEditor1: TValueListEditor;
    MemoIn: TMemo;
    spl1: TSplitter;
    btnAPP: TSpeedButton;
    actApplyInText: TAction;
    pnlTop_A: TPanel;
    chk_AddTagText: TCheckBox;
    edt_TagComment: TEdit;
    FDMemTACTIVE: TBooleanField;
    dbchkACTIVE: TDBCheckBox;
    pgCtrl: TPageControl;
    tsDirect: TTabSheet;
    tsComment: TTabSheet;
    mmoComment: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FileSaveAs1Accept(Sender: TObject);
    procedure FileOpen1Accept(Sender: TObject);
    procedure actRenameGroupUpdate(Sender: TObject);
    procedure actRenameGroupExecute(Sender: TObject);
    procedure FDMemTAfterScroll(DataSet: TDataSet);
    procedure actApplyInTextUpdate(Sender: TObject);
    procedure actApplyInTextExecute(Sender: TObject);
    procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure DBGrid1ColExit(Sender: TObject);
    procedure DBGrid1KeyPress(Sender: TObject; var Key: Char);
    procedure dbchkACTIVEClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DPForm: TDPForm;

implementation

{$R *.dfm}

uses u_injectFuncs;

procedure TDPForm.actApplyInTextExecute(Sender: TObject);
var LList:TStrings;
begin
  LList:=TStringList.Create;
  try
    LList.Text:=MemoIn.Lines.Text;
    LList.Delimiter:='|';
    FDMemT.Edit;
    FDMemT.FieldByName('INTEXT').AsWideString:=LList.DelimitedText;
    FDMemT.Post;
  finally
    LList.Free;
  end;
end;

procedure TDPForm.actApplyInTextUpdate(Sender: TObject);
begin
   TAction(Sender).Enabled:=(FDMemT.Active=true) and (Trim(MemoIn.Lines.Text)<>'');
end;

procedure TDPForm.actRenameGroupExecute(Sender: TObject);
var LAct: TInjectActions;
    LCode:integer;
    LDir,LTagReplText:string;
begin
   LDir:='';
   LAct:=TInjectActions.Create(0);
   FDMemT.DisableControls;
   try
     LAct.Clearparams;
     FDMemT.First;
     // find project Path in records
     while Not(FDMemT.Eof) do
       begin
         if (FDMemT.FieldByName('ACTIVE').AsBoolean=true) and
            (FDMemT.FieldByName('RCODE').AsInteger=1) then
             begin
               LDir:=IncludeTrailingPathDelimiter(FDMemT.FieldByName('FILENAME').AsWideString);
               break;
             end;
         FDMemT.Next;
       end;
     ///
     FDMemT.First;
     while Not(FDMemT.Eof) do
      begin
       if FDMemT.FieldByName('ACTIVE').AsBoolean=true then
        begin
            LCode:=FDMemT.FieldByName('RCODE').AsInteger;
            with FDMemT do
             case LCode of
              1:  begin
                   // see top>  LDir:=IncludeTrailingPathDelimiter(FieldByName('FILENAME').AsWideString);
                  end;
              4:  Lact.AddToSections(Ldir+FieldByName('FILENAME').AsWideString,
                                     FieldByName('INTEXT').AsWideString,true);
              8:  Lact.AddToSections(LDir+FieldByName('FILENAME').AsWideString,
                                     FieldByName('INTEXT').AsWideString,false);
              16: Lact.AddToProject(LDir+FieldByName('FILENAME').AsWideString,
                                     FieldByName('INTEXT').AsWideString,true); // true!
              32: begin
                    LTagReplText:=FieldByName('INTEXT').AsWideString;
                    if chk_AddTagText.Checked=true then
                       LTagReplText:=edt_TagComment.Text+'|'+LTagReplText;
                    ///
                    Lact.ReplaceTag(LDir+FieldByName('FILENAME').AsWideString,
                                     FieldByName('TAGNAME').AsWideString,
                                     LTagReplText);
                  end;
              33: Lact.InsertProjFormData(LDir+FieldByName('FILENAME').AsWideString,
                                          FieldByName('INTEXT').AsWideString);
             end;
         end;
        FDMemT.Next;
      end;
     if LAct.IsReplaced then
        ShowMessage('Replace apply to files!');
   finally
     FDMemT.EnableControls;
     LAct.Free;
   end;
end;

procedure TDPForm.actRenameGroupUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled:=(FDMemT.Active=true) and (FDMemT.RecordCount>0);
end;

procedure TDPForm.dbchkACTIVEClick(Sender: TObject);
begin
if dbchkACTIVE.Checked then
 dbchkACTIVE.Caption := dbchkACTIVE.ValueChecked
 else
 dbchkACTIVE.Caption := dbchkACTIVE.ValueUnChecked;
end;

procedure TDPForm.DBGrid1ColExit(Sender: TObject);
begin
  if DBGrid1.SelectedField.FieldName = dbchkACTIVE.DataField then
       dbchkACTIVE.Visible := False
end;

procedure TDPForm.DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect;
  DataCol: Integer; Column: TColumn; State: TGridDrawState);
const IsChecked : array[Boolean] of Integer =
 (DFCS_BUTTONCHECK, DFCS_BUTTONCHECK or DFCS_CHECKED);
var
 DrawState: Integer;
 DrawRect: TRect;
begin
 if (gdFocused in State) then
  begin
     if (Column.Field.FieldName = dbchkACTIVE.DataField) then
      begin
        dbchkACTIVE.Left := Rect.Left + DBGrid1.Left + 2;
        dbchkACTIVE.Top := Rect.Top + DBGrid1.top + 2;
        dbchkACTIVE.Width := Rect.Right - Rect.Left;
        dbchkACTIVE.Height := Rect.Bottom - Rect.Top;
       dbchkACTIVE.Visible := True;
     end
  end
 else
   begin
    if (Column.Field.FieldName = dbchkACTIVE.DataField) then
      begin
        DrawRect:=Rect;
        InflateRect(DrawRect,-1,-1);
        DrawState := ISChecked[Column.Field.AsBoolean];
        DBGrid1.Canvas.FillRect(Rect);
        DrawFrameControl(DBGrid1.Canvas.Handle, DrawRect,DFC_BUTTON, DrawState);
      end;
   end;
end;

procedure TDPForm.DBGrid1KeyPress(Sender: TObject; var Key: Char);
begin
  if (key = Chr(9)) then Exit;

 if (DBGrid1.SelectedField.FieldName = dbchkACTIVE.DataField) then
 begin
  dbchkACTIVE.SetFocus;
  SendMessage(dbchkACTIVE.Handle, WM_Char, word(Key), 0);
 end;
end;

procedure TDPForm.FDMemTAfterScroll(DataSet: TDataSet);
begin
  MemoIn.Lines.Delimiter:='|';
  MemoIn.Lines.DelimitedText:=FDMemT.FieldByName('INTEXT').AsWideString;
  MemoIn.SelStart:=0;
end;

procedure TDPForm.FileOpen1Accept(Sender: TObject);
begin
  FDMemT.Open;
 FDMemT.EmptyDataSet;
 FDMemT.LoadFromFile(FileOpen1.Dialog.FileName,sfXML);
{ DBGrid1.Columns[1].Width:=100;
 DBGrid1.Columns[2].Width:=200;
 DBGrid1.Columns[3].Width:=420;
 }
 FDMemT.First;
end;

procedure TDPForm.FileSaveAs1Accept(Sender: TObject);
begin
 FDMemT.SaveToFile(FileSaveAs1.Dialog.FileName,sfXML);
end;

procedure TDPForm.FormCreate(Sender: TObject);
begin
 // dlgopen1.InitialDir:=ExtractFileDir(ParamStr(0));
 // dlgSave1.InitialDir:=ExtractFileDir(ParamStr(0));
  dbchkACTIVE.ValueChecked := '';
  dbchkACTIVE.ValueUnChecked := '';
  dbchkACTIVE.Color:=DBGrid1.Color;
  ///
  ///
  pgCtrl.ActivePageIndex:=0;
end;

end.
