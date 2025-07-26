unit ImageConfigForm;

interface

uses
  Windows, SysUtils, Classes, Controls, Graphics, Forms, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, Spin, ExtDlgs, Math, PngImage, GIFImg;

type
  TImageStretchMode = (ismNone, ismStretch, ismProportional, ismCenter);

  TImageConfig = record
    ImagePath: string;
    Width: Integer;
    Height: Integer;
    StretchMode: TImageStretchMode;
    Transparency: Byte; // 0-255
    SendToBack: Boolean;
    BlendMode: string;
    ShowBorder: Boolean;
    BorderColor: TColor;
    BackgroundColor: TColor;
    UseBackground: Boolean;
    AnimationSpeed: Integer; // NEW: Animation speed in milliseconds (10-1000)
    EnableAnimation: Boolean; // NEW: Whether to animate GIFs
  end;

  TfrmImageConfig = class(TForm)
    pnlMain: TPanel;
    grpImageFile: TGroupBox;
    lblImagePath: TLabel;
    edtImagePath: TEdit;
    btnBrowse: TButton;
    grpSize: TGroupBox;
    lblWidth: TLabel;
    edtWidth: TSpinEdit;
    lblHeight: TLabel;
    edtHeight: TSpinEdit;
    chkMaintainAspect: TCheckBox;
    grpAppearance: TGroupBox;
    lblStretchMode: TLabel;
    cmbStretchMode: TComboBox;
    lblTransparency: TLabel;
    trkTransparency: TTrackBar;
    lblTransValue: TLabel;
    chkSendToBack: TCheckBox;
    grpBorder: TGroupBox;
    chkShowBorder: TCheckBox;
    lblBorderColor: TLabel;
    pnlBorderColor: TPanel;
    grpBackground: TGroupBox;
    chkUseBackground: TCheckBox;
    lblBackgroundColor: TLabel;
    pnlBackgroundColor: TPanel;
    grpAnimation: TGroupBox;
    chkEnableAnimation: TCheckBox;
    lblAnimationSpeed: TLabel;
    trkAnimationSpeed: TTrackBar;
    lblSpeedValue: TLabel;
    lblSpeedHint: TLabel;
    grpPreview: TGroupBox;
    imgPreview: TImage;
    pnlPreviewBg: TPanel;
    pnlButtons: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    btnReset: TButton;
    OpenPictureDialog: TOpenPictureDialog;
    ColorDialog: TColorDialog;

    procedure FormCreate(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure edtImagePathChange(Sender: TObject);
    procedure trkTransparencyChange(Sender: TObject);
    procedure cmbStretchModeChange(Sender: TObject);
    procedure edtWidthChange(Sender: TObject);
    procedure edtHeightChange(Sender: TObject);
    procedure chkMaintainAspectClick(Sender: TObject);
    procedure chkShowBorderClick(Sender: TObject);
    procedure pnlBorderColorClick(Sender: TObject);
    procedure chkUseBackgroundClick(Sender: TObject);
    procedure pnlBackgroundColorClick(Sender: TObject);
    procedure chkEnableAnimationClick(Sender: TObject);
    procedure trkAnimationSpeedChange(Sender: TObject);
    procedure UpdatePreview;

  private
    FImageConfig: TImageConfig;
    FOriginalAspectRatio: Double;
    FUpdatingSize: Boolean;
    FIsGifFile: Boolean;

    procedure LoadImagePreview(const APath: string);
    procedure ApplyTransparencyToPreview;
    procedure ResetToDefaults;
    procedure UpdateAnimationControls;
    function IsGifFile(const FileName: string): Boolean;

  public
    property ImageConfig: TImageConfig read FImageConfig write FImageConfig;

    class function ShowConfigDialog(var AConfig: TImageConfig): Boolean;
  end;

implementation

{$R *.dfm}

{ TfrmImageConfig }

function TfrmImageConfig.IsGifFile(const FileName: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(FileName));
  Result := (Ext = '.gif');
end;

class function TfrmImageConfig.ShowConfigDialog(var AConfig: TImageConfig): Boolean;
var
  Form: TfrmImageConfig;
begin
  Result := False;
  Form := TfrmImageConfig.Create(nil);
  try
    Form.ImageConfig := AConfig;

    // Load current settings into form
    Form.edtImagePath.Text := AConfig.ImagePath;
    Form.edtWidth.Value := AConfig.Width;
    Form.edtHeight.Value := AConfig.Height;
    Form.cmbStretchMode.ItemIndex := Ord(AConfig.StretchMode);
    Form.trkTransparency.Position := AConfig.Transparency;
    Form.chkSendToBack.Checked := AConfig.SendToBack;
    Form.chkShowBorder.Checked := AConfig.ShowBorder;
    Form.pnlBorderColor.Color := AConfig.BorderColor;
    Form.chkUseBackground.Checked := AConfig.UseBackground;
    Form.pnlBackgroundColor.Color := AConfig.BackgroundColor;
    Form.chkEnableAnimation.Checked := AConfig.EnableAnimation;
    Form.trkAnimationSpeed.Position := AConfig.AnimationSpeed;

    Form.UpdatePreview;
    Form.UpdateAnimationControls;

    if Form.ShowModal = mrOK then
    begin
      AConfig := Form.ImageConfig;
      Result := True;
    end;
  finally
    Form.Free;
  end;
end;

procedure TfrmImageConfig.FormCreate(Sender: TObject);
begin
  FUpdatingSize := False;
  FOriginalAspectRatio := 1.0;
  FIsGifFile := False;

  // Setup combo box
  cmbStretchMode.Items.Clear;
  cmbStretchMode.Items.Add('None (Original Size)');
  cmbStretchMode.Items.Add('Stretch to Fit');
  cmbStretchMode.Items.Add('Proportional');
  cmbStretchMode.Items.Add('Center');
  cmbStretchMode.ItemIndex := 2; // Default to Proportional

  // Setup transparency trackbar
  trkTransparency.Min := 0;
  trkTransparency.Max := 255;
  trkTransparency.Position := 0; // No transparency by default

  // Setup animation speed trackbar
  trkAnimationSpeed.Min := 10;   // 10ms = very fast
  trkAnimationSpeed.Max := 1000; // 1000ms = very slow
  trkAnimationSpeed.Position := 100; // 100ms = default speed

  // Set defaults
  ResetToDefaults;

  // Setup preview background
  pnlPreviewBg.Color := clWhite;
  imgPreview.Transparent := True;

  // Update animation controls
  UpdateAnimationControls;
end;

procedure TfrmImageConfig.ResetToDefaults;
begin
  FImageConfig.Width := 200;
  FImageConfig.Height := 150;
  FImageConfig.StretchMode := ismProportional;
  FImageConfig.Transparency := 0; // No transparency by default
  FImageConfig.SendToBack := True;
  FImageConfig.BlendMode := 'Normal';
  FImageConfig.ShowBorder := False;
  FImageConfig.BorderColor := clGray;
  FImageConfig.UseBackground := False;
  FImageConfig.BackgroundColor := clWhite;
  FImageConfig.EnableAnimation := True; // Animation enabled by default
  FImageConfig.AnimationSpeed := 100; // 100ms default speed

  edtWidth.Value := FImageConfig.Width;
  edtHeight.Value := FImageConfig.Height;
  cmbStretchMode.ItemIndex := Ord(FImageConfig.StretchMode);
  trkTransparency.Position := FImageConfig.Transparency;
  chkSendToBack.Checked := FImageConfig.SendToBack;
  chkShowBorder.Checked := FImageConfig.ShowBorder;
  pnlBorderColor.Color := FImageConfig.BorderColor;
  chkUseBackground.Checked := FImageConfig.UseBackground;
  pnlBackgroundColor.Color := FImageConfig.BackgroundColor;
  chkEnableAnimation.Checked := FImageConfig.EnableAnimation;
  trkAnimationSpeed.Position := FImageConfig.AnimationSpeed;
  chkMaintainAspect.Checked := True;

  UpdatePreview;
  UpdateAnimationControls;
end;

procedure TfrmImageConfig.btnBrowseClick(Sender: TObject);
begin
  if OpenPictureDialog.Execute then
  begin
    edtImagePath.Text := OpenPictureDialog.FileName;
    FImageConfig.ImagePath := OpenPictureDialog.FileName;
    FIsGifFile := IsGifFile(OpenPictureDialog.FileName);
    LoadImagePreview(OpenPictureDialog.FileName);
    UpdateAnimationControls;
  end;
end;

procedure TfrmImageConfig.LoadImagePreview(const APath: string);
var
  TempBitmap: TBitmap;
  TempGif: TGIFImage;
  TempPng: TPngImage;
begin
  if not FileExists(APath) then Exit;

  try
    if FIsGifFile then
    begin
      // Handle GIF files
      TempGif := TGIFImage.Create;
      try
        TempGif.LoadFromFile(APath);

        // Store original aspect ratio
        if TempGif.Height > 0 then
          FOriginalAspectRatio := TempGif.Width / TempGif.Height
        else
          FOriginalAspectRatio := 1.0;

        // Auto-adjust size based on image if not manually set
        if not FUpdatingSize then
        begin
          FUpdatingSize := True;
          try
            if TempGif.Width > 0 then
            begin
              edtWidth.Value := Min(400, Max(50, TempGif.Width));
              if chkMaintainAspect.Checked then
                edtHeight.Value := Round(edtWidth.Value / FOriginalAspectRatio);
            end;
          finally
            FUpdatingSize := False;
          end;
        end;

        // Convert first frame to bitmap for preview
        TempBitmap := TBitmap.Create;
        try
          TempBitmap.SetSize(TempGif.Width, TempGif.Height);
          TempBitmap.Canvas.Draw(0, 0, TempGif);
          imgPreview.Picture.Assign(TempBitmap);
        finally
          TempBitmap.Free;
        end;

      finally
        TempGif.Free;
      end;
    end
    else if LowerCase(ExtractFileExt(APath)) = '.png' then
    begin
      // Handle PNG files
      TempPng := TPngImage.Create;
      try
        TempPng.LoadFromFile(APath);

        // Store original aspect ratio
        if TempPng.Height > 0 then
          FOriginalAspectRatio := TempPng.Width / TempPng.Height
        else
          FOriginalAspectRatio := 1.0;

        // Auto-adjust size based on image if not manually set
        if not FUpdatingSize then
        begin
          FUpdatingSize := True;
          try
            if TempPng.Width > 0 then
            begin
              edtWidth.Value := Min(400, Max(50, TempPng.Width));
              if chkMaintainAspect.Checked then
                edtHeight.Value := Round(edtWidth.Value / FOriginalAspectRatio);
            end;
          finally
            FUpdatingSize := False;
          end;
        end;

        // Convert to bitmap for preview
        TempBitmap := TBitmap.Create;
        try
          TempBitmap.SetSize(TempPng.Width, TempPng.Height);
          TempPng.Draw(TempBitmap.Canvas, TempBitmap.Canvas.ClipRect);
          imgPreview.Picture.Assign(TempBitmap);
        finally
          TempBitmap.Free;
        end;

      finally
        TempPng.Free;
      end;
    end
    else
    begin
      // Handle other image formats (JPG, BMP, etc.)
      TempBitmap := TBitmap.Create;
      try
        TempBitmap.LoadFromFile(APath);

        // Store original aspect ratio
        if TempBitmap.Height > 0 then
          FOriginalAspectRatio := TempBitmap.Width / TempBitmap.Height
        else
          FOriginalAspectRatio := 1.0;

        // Auto-adjust size based on image if not manually set
        if not FUpdatingSize then
        begin
          FUpdatingSize := True;
          try
            if TempBitmap.Width > 0 then
            begin
              edtWidth.Value := Min(400, Max(50, TempBitmap.Width));
              if chkMaintainAspect.Checked then
                edtHeight.Value := Round(edtWidth.Value / FOriginalAspectRatio);
            end;
          finally
            FUpdatingSize := False;
          end;
        end;

        imgPreview.Picture.Assign(TempBitmap);

      finally
        TempBitmap.Free;
      end;
    end;

    UpdatePreview;

  except
    // Handle image loading errors
    imgPreview.Picture := nil;
    ShowMessage('Unable to load image preview. Please check the file format.');
  end;
end;

procedure TfrmImageConfig.UpdateAnimationControls;
begin
  // Enable/disable animation controls based on file type
  grpAnimation.Enabled := FIsGifFile;
  chkEnableAnimation.Enabled := FIsGifFile;
  lblAnimationSpeed.Enabled := FIsGifFile and chkEnableAnimation.Checked;
  trkAnimationSpeed.Enabled := FIsGifFile and chkEnableAnimation.Checked;
  lblSpeedValue.Enabled := FIsGifFile and chkEnableAnimation.Checked;
  lblSpeedHint.Enabled := FIsGifFile and chkEnableAnimation.Checked;

  if FIsGifFile then
  begin
    grpAnimation.Caption := ' GIF Animation Settings ';
    if chkEnableAnimation.Checked then
      lblSpeedValue.Caption := Format('%d ms', [trkAnimationSpeed.Position])
    else
      lblSpeedValue.Caption := 'Disabled';
  end
  else
  begin
    grpAnimation.Caption := ' Animation Settings (GIF files only) ';
    lblSpeedValue.Caption := 'N/A';
  end;
end;

procedure TfrmImageConfig.UpdatePreview;
begin
  if not Assigned(imgPreview.Picture.Graphic) then Exit;

  // Apply stretch mode
  case TImageStretchMode(cmbStretchMode.ItemIndex) of
    ismNone:
    begin
      imgPreview.Stretch := False;
      imgPreview.Proportional := False;
      imgPreview.Center := True;
    end;
    ismStretch:
    begin
      imgPreview.Stretch := True;
      imgPreview.Proportional := False;
      imgPreview.Center := False;
    end;
    ismProportional:
    begin
      imgPreview.Stretch := True;
      imgPreview.Proportional := True;
      imgPreview.Center := True;
    end;
    ismCenter:
    begin
      imgPreview.Stretch := False;
      imgPreview.Proportional := False;
      imgPreview.Center := True;
    end;
  end;

  // Update preview background based on background settings
  if chkUseBackground.Checked then
    pnlPreviewBg.Color := pnlBackgroundColor.Color
  else
    pnlPreviewBg.Color := clWhite;

  ApplyTransparencyToPreview;

  // Update transparency label
  lblTransValue.Caption := Format('%d%% Transparent', [Round((trkTransparency.Position / 255) * 100)]);
end;

procedure TfrmImageConfig.ApplyTransparencyToPreview;
begin
  // Note: This is a simplified preview. Actual transparency will be applied in the overlay
  if trkTransparency.Position > 200 then
    pnlPreviewBg.Color := clSilver
  else if trkTransparency.Position > 100 then
    pnlPreviewBg.Color := clLtGray
  else if not chkUseBackground.Checked then
    pnlPreviewBg.Color := clWhite;
end;

procedure TfrmImageConfig.btnOKClick(Sender: TObject);
begin
  // Validate settings
  if Trim(edtImagePath.Text) = '' then
  begin
    ShowMessage('Please select an image file.');
    edtImagePath.SetFocus;
    Exit;
  end;

  if not FileExists(edtImagePath.Text) then
  begin
    ShowMessage('Selected image file does not exist.');
    btnBrowse.SetFocus;
    Exit;
  end;

  // Save configuration
  FImageConfig.ImagePath := edtImagePath.Text;
  FImageConfig.Width := edtWidth.Value;
  FImageConfig.Height := edtHeight.Value;
  FImageConfig.StretchMode := TImageStretchMode(cmbStretchMode.ItemIndex);
  FImageConfig.Transparency := trkTransparency.Position;
  FImageConfig.SendToBack := chkSendToBack.Checked;
  FImageConfig.ShowBorder := chkShowBorder.Checked;
  FImageConfig.BorderColor := pnlBorderColor.Color;
  FImageConfig.UseBackground := chkUseBackground.Checked;
  FImageConfig.BackgroundColor := pnlBackgroundColor.Color;
  FImageConfig.EnableAnimation := chkEnableAnimation.Checked;
  FImageConfig.AnimationSpeed := trkAnimationSpeed.Position;

  ModalResult := mrOK;
end;

procedure TfrmImageConfig.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmImageConfig.btnResetClick(Sender: TObject);
begin
  ResetToDefaults;
end;

procedure TfrmImageConfig.edtImagePathChange(Sender: TObject);
begin
  FIsGifFile := IsGifFile(edtImagePath.Text);
  UpdateAnimationControls;
  if FileExists(edtImagePath.Text) then
    LoadImagePreview(edtImagePath.Text);
end;

procedure TfrmImageConfig.trkTransparencyChange(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TfrmImageConfig.cmbStretchModeChange(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TfrmImageConfig.edtWidthChange(Sender: TObject);
begin
  if FUpdatingSize or not chkMaintainAspect.Checked then Exit;

  FUpdatingSize := True;
  try
    if FOriginalAspectRatio > 0 then
      edtHeight.Value := Round(edtWidth.Value / FOriginalAspectRatio);
  finally
    FUpdatingSize := False;
  end;
end;

procedure TfrmImageConfig.edtHeightChange(Sender: TObject);
begin
  if FUpdatingSize or not chkMaintainAspect.Checked then Exit;

  FUpdatingSize := True;
  try
    if FOriginalAspectRatio > 0 then
      edtWidth.Value := Round(edtHeight.Value * FOriginalAspectRatio);
  finally
    FUpdatingSize := False;
  end;
end;

procedure TfrmImageConfig.chkMaintainAspectClick(Sender: TObject);
begin
  if chkMaintainAspect.Checked and (FOriginalAspectRatio > 0) then
    edtWidthChange(nil);
end;

procedure TfrmImageConfig.chkShowBorderClick(Sender: TObject);
begin
  lblBorderColor.Enabled := chkShowBorder.Checked;
  pnlBorderColor.Enabled := chkShowBorder.Checked;
end;

procedure TfrmImageConfig.pnlBorderColorClick(Sender: TObject);
begin
  if chkShowBorder.Checked then
  begin
    ColorDialog.Color := pnlBorderColor.Color;
    if ColorDialog.Execute then
      pnlBorderColor.Color := ColorDialog.Color;
  end;
end;

procedure TfrmImageConfig.chkUseBackgroundClick(Sender: TObject);
begin
  lblBackgroundColor.Enabled := chkUseBackground.Checked;
  pnlBackgroundColor.Enabled := chkUseBackground.Checked;
  UpdatePreview;
end;

procedure TfrmImageConfig.pnlBackgroundColorClick(Sender: TObject);
begin
  if chkUseBackground.Checked then
  begin
    ColorDialog.Color := pnlBackgroundColor.Color;
    if ColorDialog.Execute then
    begin
      pnlBackgroundColor.Color := ColorDialog.Color;
      UpdatePreview;
    end;
  end;
end;

procedure TfrmImageConfig.chkEnableAnimationClick(Sender: TObject);
begin
  UpdateAnimationControls;
end;

procedure TfrmImageConfig.trkAnimationSpeedChange(Sender: TObject);
begin
  UpdateAnimationControls;
end;

end.
