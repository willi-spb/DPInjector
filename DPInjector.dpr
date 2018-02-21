program DPInjector;

uses
  Vcl.Forms,
  fm_dpInject in 'fm_dpInject.pas' {DPForm},
  u_injectFuncs in 'u_injectFuncs.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDPForm, DPForm);
  Application.Run;
end.
