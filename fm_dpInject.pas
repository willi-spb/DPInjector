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
  FireDAC.Stan.StorageXML, Vcl.StdCtrls, Vcl.Buttons;

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
    procedure FormCreate(Sender: TObject);
    procedure FileSaveAs1Accept(Sender: TObject);
    procedure FileOpen1Accept(Sender: TObject);
    procedure actRenameGroupUpdate(Sender: TObject);
    procedure actRenameGroupExecute(Sender: TObject);
    procedure FDMemTAfterScroll(DataSet: TDataSet);
    procedure actApplyInTextUpdate(Sender: TObject);
    procedure actApplyInTextExecute(Sender: TObject);
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
    LDir:string;
begin
   LDir:='';
   LAct:=TInjectActions.Create(0);
   try
     LAct.Clearparams;
     FDMemT.First;
     while Not(FDMemT.Eof) do
      begin
        LCode:=FDMemT.FieldByName('RCODE').AsInteger;
        with FDMemT do
         case LCode of
          1:  begin
                LDir:=IncludeTrailingPathDelimiter(FieldByName('FILENAME').AsWideString);
              end;
          4:  Lact.AddToSections(Ldir+FieldByName('FILENAME').AsWideString,
                                 FieldByName('INTEXT').AsWideString,true);
          8:  Lact.AddToSections(LDir+FieldByName('FILENAME').AsWideString,
                                 FieldByName('INTEXT').AsWideString,false);
          16: Lact.AddToProject(LDir+FieldByName('FILENAME').AsWideString,
                                 FieldByName('INTEXT').AsWideString,true); // true!
          32: Lact.ReplaceTag(LDir+FieldByName('FILENAME').AsWideString,
                              FieldByName('TAGNAME').AsWideString,
                                 FieldByName('INTEXT').AsWideString);
          33: Lact.InsertProjFormData(LDir+FieldByName('FILENAME').AsWideString,
                                      FieldByName('INTEXT').AsWideString);
         end;
        FDMemT.Next;
      end;
     if LAct.IsReplaced then
        ShowMessage('Replace apply to files!');
   finally
     LAct.Free;
   end;
end;

procedure TDPForm.actRenameGroupUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled:=(FDMemT.Active=true) and (FDMemT.RecordCount>0);
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
end;

end.
