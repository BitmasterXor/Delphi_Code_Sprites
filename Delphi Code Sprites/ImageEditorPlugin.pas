unit ImageEditorPlugin;

interface

uses
  Windows, SysUtils, Classes, Controls, Graphics, Forms, ExtCtrls, Messages,
  ToolsAPI, DesignIntf, Menus, Math, Vcl.Dialogs, ImageConfigForm, PngImage,
  System.Generics.Collections, Vcl.ActnList, GIFImg;

type
  // Base notifier class
  TBaseNotifier = class(TInterfacedObject, IOTANotifier)
  protected
    procedure AfterSave; virtual;
    procedure BeforeSave; virtual;
    procedure Destroyed; virtual;
    procedure Modified; virtual;
  end;

  // Forward declaration
  TImageEditorWizard = class;

  // Menu handler class (copied from LitCrypt pattern)
  TMenuHandler = class
  strict private
    Item: TMenuItem;
    Action: TProc;
    procedure OnExecute(Sender: TObject);
    constructor Create(aCaption: String; aAction: TProc; aShortcut: String);
  class var
    MenuHandlers: TObjectList<TMenuHandler>;
    FActionList: TActionList;
  public
    destructor Destroy; override;
    class constructor Create;
    class destructor Destroy;
    class procedure AddMenuItem(NTAServices: INTAServices; aCaption: String; aAction: TProc; aShortcut: String = '');
  end;

  // Enhanced image overlay with GIF support and animation speed control
  TImageOverlay = class(TCustomControl)
  private
    FLine: Integer;
    FColumn: Integer;
    FImagePath: string;
    FConfig: TImageConfig;
    FPngImage: TPngImage;
    FGifImage: TGIFImage;
    FIsGif: Boolean;
    FDragging: Boolean;
    FResizing: Boolean;
    FDragStartPos: TPoint;
    FResizeHandle: Integer; // 0=none, 1=TL, 2=TR, 3=BL, 4=BR
    FStartRect: TRect;
    FAnimationTimer: TTimer;

  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DblClick; override;
    procedure CreateParams(var Params: TCreateParams); override;
    function GetResizeHandle(X, Y: Integer): Integer;
    procedure OnAnimationTimer(Sender: TObject);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure LoadImage(const AImagePath: string; const AConfig: TImageConfig);
    procedure SetPosition(ALine, AColumn: Integer);
    procedure UpdateAnimationSettings(const AConfig: TImageConfig);

    property Line: Integer read FLine write FLine;
    property Column: Integer read FColumn write FColumn;
    property ImagePath: string read FImagePath;
    property IsGif: Boolean read FIsGif;
  end;

  // Enhanced editor notifier
  TImageEditorNotifier = class(TBaseNotifier, IOTAEditorNotifier)
  private
    FWizard: TImageEditorWizard;
    FEditor: IOTAEditor;
    FNotifierIndex: Integer;
    FEditorValid: Boolean;
  protected
    procedure Destroyed; override;
  public
    constructor Create(AWizard: TImageEditorWizard; AEditor: IOTAEditor);
    destructor Destroy; override;
    procedure ViewActivated(const View: IOTAEditView);
    procedure ViewNotification(const View: IOTAEditView; Operation: TOperation);
    procedure MarkEditorInvalid;
    property NotifierIndex: Integer read FNotifierIndex write FNotifierIndex;
    property EditorValid: Boolean read FEditorValid;
  end;

  // Main plugin wizard
  TImageEditorWizard = class(TBaseNotifier, IOTAWizard, IOTAMenuWizard)
  private
    FImageOverlays: TList;
    FEditorNotifiers: TList;
    FImagesVisible: Boolean;

    procedure RegisterEditorNotifiers;
    procedure UnregisterEditorNotifiers;
    function GetCurrentSourceEditor: IOTASourceEditor;
    function GetCurrentEditView: IOTAEditView;
  public
    constructor Create;
    destructor Destroy; override;

    // IOTAWizard methods
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;

    // IOTAMenuWizard
    function GetMenuText: string;

    // Custom methods
    procedure AddImageToEditor(const AConfig: TImageConfig; Line, Column: Integer);
    procedure RemoveAllImages;
    procedure ToggleImageVisibility;
    procedure RemoveImageOverlay(AOverlay: TImageOverlay);
    procedure ShowImageConfigDialog;

    property ImagesVisible: Boolean read FImagesVisible;
  end;

var
  ImageWizard: TImageEditorWizard;
  ImageWizardIndex: Integer = -1;

// Wrapper procedures for TProc compatibility
procedure DoAddImage;
procedure DoToggleVisibility;
procedure DoClearAllImages;

procedure Register;

implementation

var
  MenusCreated: Boolean = False;

// Helper function to detect image type
function IsGifFile(const FileName: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(FileName));
  Result := (Ext = '.gif');
end;

// Wrapper procedures for TProc compatibility
procedure DoAddImage;
begin
  if Assigned(ImageWizard) then
    ImageWizard.ShowImageConfigDialog;
end;

procedure DoToggleVisibility;
begin
  if Assigned(ImageWizard) then
    ImageWizard.ToggleImageVisibility;
end;

procedure DoClearAllImages;
begin
  if Assigned(ImageWizard) then
  begin
    if MessageDlg('Remove all images from all editors?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      ImageWizard.RemoveAllImages;
  end;
end;

procedure Register;
var
  NTAServices: INTAServices;
begin
  // Create the wizard
  ImageWizard := TImageEditorWizard.Create;
  ImageWizardIndex := (BorlandIDEServices as IOTAWizardServices).AddWizard(ImageWizard);

  if not Supports(BorlandIDEServices, INTAServices, NTAServices) then
    exit;

  // Use the same robust menu creation approach as LitCrypt
  TThread.CreateAnonymousThread(
    procedure
    begin
      while not Application.Terminated do begin
        if NTAServices.MainMenu.Items.Count = 0 then begin
          Sleep(1000);
          continue;
        end;
        TThread.Queue(nil,
          procedure
          begin
            if not MenusCreated then
            begin
              TMenuHandler.AddMenuItem(NTAServices, '-', nil);
              TMenuHandler.AddMenuItem(NTAServices, 'Add &Image to Editor...', DoAddImage);
              TMenuHandler.AddMenuItem(NTAServices, 'Toggle Image &Visibility', DoToggleVisibility);
              TMenuHandler.AddMenuItem(NTAServices, '&Clear All Images', DoClearAllImages);
              MenusCreated := True;
            end;
          end);
        break;
      end;
    end).Start;
end;

{ TMenuHandler }

class constructor TMenuHandler.Create;
begin
  MenuHandlers := TObjectList<TMenuHandler>.Create;
  FActionList := TActionList.Create(nil);
end;

class destructor TMenuHandler.Destroy;
begin
  MenuHandlers.Free;
  FActionList.Free;
end;

constructor TMenuHandler.Create(aCaption: String; aAction: TProc; aShortcut: String);
var
  MyAction: TAction;
begin
  inherited Create;
  Action := aAction;
  MyAction := TAction.Create(FActionList);
  MyAction.Caption := aCaption;
  MyAction.OnExecute := OnExecute;
  MyAction.ActionList := FActionList;
  MyAction.Enabled := True;
  MyAction.Visible := True;

  Item := TMenuItem.Create(nil);
  Item.Action := MyAction;
  Item.Caption := aCaption;

  // Display shortcut in menu caption for reference
  if aShortcut <> '' then
    Item.Caption := aCaption + #9 + aShortcut;
end;

destructor TMenuHandler.Destroy;
begin
  FreeAndNil(Item);
  inherited;
end;

procedure TMenuHandler.OnExecute(Sender: TObject);
begin
  if assigned(action) then
    Action;
end;

class procedure TMenuHandler.AddMenuItem(NTAServices: INTAServices; aCaption: String; aAction: TProc; aShortcut: String = '');
begin
  var handler := TMenuHandler.Create(aCaption, aAction, aShortcut);
  MenuHandlers.Add(handler);

  // Adding menu items to the top of the Tools menu because all
  // the menu items under "Configure Tools..." get deleted whenever you
  // open its dialog.
  NTAServices.AddActionMenu('ToolsMenu', nil, handler.Item, False, True);
end;

{ TBaseNotifier }

procedure TBaseNotifier.AfterSave;
begin
end;

procedure TBaseNotifier.BeforeSave;
begin
end;

procedure TBaseNotifier.Destroyed;
begin
end;

procedure TBaseNotifier.Modified;
begin
end;

{ TImageOverlay }

constructor TImageOverlay.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPngImage := TPngImage.Create;
  FGifImage := TGIFImage.Create;
  FIsGif := False;
  FDragging := False;
  FResizing := False;
  FResizeHandle := 0;
  Width := 200;
  Height := 150;
  Cursor := crSizeAll;

  // Create animation timer for GIFs
  FAnimationTimer := TTimer.Create(Self);
  FAnimationTimer.Enabled := False;
  FAnimationTimer.OnTimer := OnAnimationTimer;
  FAnimationTimer.Interval := 100; // Default interval, will be set by config

  // Make it interactive and visible
  ControlStyle := ControlStyle - [csOpaque];
  SetBounds(0, 0, Width, Height);
end;

procedure TImageOverlay.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // Keep it behind text but visible
  Params.ExStyle := Params.ExStyle and not WS_EX_TOPMOST;
end;

destructor TImageOverlay.Destroy;
begin
  FAnimationTimer.Enabled := False;
  FAnimationTimer.Free;
  FPngImage.Free;
  FGifImage.Free;
  inherited Destroy;
end;

procedure TImageOverlay.OnAnimationTimer(Sender: TObject);
begin
  if FIsGif and Assigned(FGifImage) and not FGifImage.Empty and FConfig.EnableAnimation then
  begin
    // Invalidate to trigger a repaint for next frame
    Invalidate;
  end;
end;

procedure TImageOverlay.LoadImage(const AImagePath: string; const AConfig: TImageConfig);
begin
  FImagePath := AImagePath;
  FConfig := AConfig;
  FIsGif := IsGifFile(AImagePath);

  // Stop any existing animation
  FAnimationTimer.Enabled := False;

  try
    if FileExists(AImagePath) then
    begin
      if FIsGif then
      begin
        // Load GIF
        FGifImage.LoadFromFile(AImagePath);
        Width := AConfig.Width;
        Height := AConfig.Height;

        // Start animation if it's an animated GIF and animation is enabled
        if (FGifImage.Images.Count > 1) and AConfig.EnableAnimation then
        begin
          FGifImage.Animate := True;
          FAnimationTimer.Enabled := True;
          // Use user-specified animation speed
          FAnimationTimer.Interval := AConfig.AnimationSpeed;
        end
        else
        begin
          // Static display for single frame or disabled animation
          FGifImage.Animate := False;
        end;
      end
      else
      begin
        // Load PNG
        FPngImage.LoadFromFile(AImagePath);
        Width := AConfig.Width;
        Height := AConfig.Height;
      end;
      Invalidate;
    end;
  except
    // Handle errors silently
    FAnimationTimer.Enabled := False;
  end;
end;

procedure TImageOverlay.UpdateAnimationSettings(const AConfig: TImageConfig);
begin
  FConfig := AConfig;

  if FIsGif and Assigned(FGifImage) and not FGifImage.Empty then
  begin
    if (FGifImage.Images.Count > 1) and AConfig.EnableAnimation then
    begin
      FGifImage.Animate := True;
      FAnimationTimer.Interval := AConfig.AnimationSpeed;
      FAnimationTimer.Enabled := True;
    end
    else
    begin
      FAnimationTimer.Enabled := False;
      FGifImage.Animate := False;
    end;
    Invalidate;
  end;
end;

procedure TImageOverlay.SetPosition(ALine, AColumn: Integer);
begin
  FLine := ALine;
  FColumn := AColumn;

  // Simple position calculation
  Left := FColumn * 8 + 50;
  Top := (FLine - 1) * 14 + 50;

  // Keep within parent bounds
  if Assigned(Parent) then
  begin
    if Left + Width > Parent.Width then
      Left := Parent.Width - Width;
    if Top + Height > Parent.Height then
      Top := Parent.Height - Height;
    if Left < 0 then Left := 0;
    if Top < 0 then Top := 0;
  end;
end;

function TImageOverlay.GetResizeHandle(X, Y: Integer): Integer;
const
  HANDLE_SIZE = 8;
begin
  Result := 0;

  // Check for resize handles in corners
  if (X <= HANDLE_SIZE) and (Y <= HANDLE_SIZE) then
    Result := 1 // Top-left
  else if (X >= Width - HANDLE_SIZE) and (Y <= HANDLE_SIZE) then
    Result := 2 // Top-right
  else if (X <= HANDLE_SIZE) and (Y >= Height - HANDLE_SIZE) then
    Result := 3 // Bottom-left
  else if (X >= Width - HANDLE_SIZE) and (Y >= Height - HANDLE_SIZE) then
    Result := 4; // Bottom-right
end;

procedure TImageOverlay.Paint;
const
  HANDLE_SIZE = 8;
var
  DrawRect: TRect;
  BlendFunc: TBlendFunction;
  Alpha: Byte;
  TempBmp: TBitmap;
begin
  // Calculate draw rectangle
  DrawRect := ClientRect;

  // Fill background if requested
  if FConfig.UseBackground then
  begin
    Canvas.Brush.Color := FConfig.BackgroundColor;
    Canvas.Brush.Style := bsSolid;
    Canvas.FillRect(DrawRect);
  end
  else
  begin
    // Clear background for transparency
    Canvas.Brush.Style := bsClear;
  end;

  // Draw the appropriate image type
  if FIsGif and Assigned(FGifImage) and not FGifImage.Empty then
  begin
    // Draw GIF with transparency support
    Alpha := 255 - FConfig.Transparency;

    if Alpha < 255 then
    begin
      // Use AlphaBlend for transparency
      BlendFunc.BlendOp := AC_SRC_OVER;
      BlendFunc.BlendFlags := 0;
      BlendFunc.SourceConstantAlpha := Alpha;
      BlendFunc.AlphaFormat := 0;

      // Create temp bitmap
      TempBmp := TBitmap.Create;
      try
        TempBmp.SetSize(Width, Height);
        TempBmp.Canvas.StretchDraw(DrawRect, FGifImage);

        Windows.AlphaBlend(
          Canvas.Handle, 0, 0, Width, Height,
          TempBmp.Canvas.Handle, 0, 0, Width, Height,
          BlendFunc
        );
      finally
        TempBmp.Free;
      end;
    end
    else
    begin
      // Direct draw if no transparency
      Canvas.StretchDraw(DrawRect, FGifImage);
    end;
  end
  else if Assigned(FPngImage) and not FPngImage.Empty then
  begin
    // Draw PNG with proper alpha blending for transparency
    Alpha := 255 - FConfig.Transparency;

    if Alpha < 255 then
    begin
      // Use AlphaBlend for transparency
      BlendFunc.BlendOp := AC_SRC_OVER;
      BlendFunc.BlendFlags := 0;
      BlendFunc.SourceConstantAlpha := Alpha;
      BlendFunc.AlphaFormat := 0;

      // Create temp bitmap
      TempBmp := TBitmap.Create;
      try
        TempBmp.SetSize(Width, Height);
        FPngImage.Draw(TempBmp.Canvas, DrawRect);

        Windows.AlphaBlend(
          Canvas.Handle, 0, 0, Width, Height,
          TempBmp.Canvas.Handle, 0, 0, Width, Height,
          BlendFunc
        );
      finally
        TempBmp.Free;
      end;
    end
    else
    begin
      // Direct draw if no transparency
      FPngImage.Draw(Canvas, DrawRect);
    end;
  end;

  // Draw border if enabled
  if FConfig.ShowBorder then
  begin
    Canvas.Pen.Color := FConfig.BorderColor;
    Canvas.Pen.Width := 1;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(0, 0, Width, Height);
  end;

  // Draw resize handles when mouse is over
  if PtInRect(ClientRect, ScreenToClient(Mouse.CursorPos)) then
  begin
    Canvas.Pen.Color := clBlack;
    Canvas.Pen.Width := 1;
    Canvas.Brush.Color := clWhite;
    Canvas.Brush.Style := bsSolid;

    // Draw corner resize handles
    Canvas.Rectangle(0, 0, HANDLE_SIZE, HANDLE_SIZE);
    Canvas.Rectangle(Width - HANDLE_SIZE, 0, Width, HANDLE_SIZE);
    Canvas.Rectangle(0, Height - HANDLE_SIZE, HANDLE_SIZE, Height);
    Canvas.Rectangle(Width - HANDLE_SIZE, Height - HANDLE_SIZE, Width, Height);
  end;
end;

procedure TImageOverlay.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);

  if Button = mbLeft then
  begin
    FResizeHandle := GetResizeHandle(X, Y);
    FDragStartPos := Point(X, Y);
    FStartRect := BoundsRect;

    if FResizeHandle > 0 then
    begin
      FResizing := True;
      // Set appropriate cursor for resize direction
      case FResizeHandle of
        1, 4: Cursor := crSizeNWSE; // Top-left, Bottom-right
        2, 3: Cursor := crSizeNESW; // Top-right, Bottom-left
      end;
    end
    else
    begin
      FDragging := True;
      Cursor := crSizeAll;
    end;

    BringToFront;
  end;
end;

procedure TImageOverlay.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  DeltaX, DeltaY: Integer;
  NewWidth, NewHeight: Integer;
  NewLeft, NewTop: Integer;
begin
  inherited MouseMove(Shift, X, Y);

  if not (ssLeft in Shift) then
  begin
    // Update cursor based on position when not dragging
    FResizeHandle := GetResizeHandle(X, Y);
    case FResizeHandle of
      0: Cursor := crSizeAll;
      1, 4: Cursor := crSizeNWSE;
      2, 3: Cursor := crSizeNESW;
    end;
    Exit;
  end;

  DeltaX := X - FDragStartPos.X;
  DeltaY := Y - FDragStartPos.Y;

  if FResizing and (FResizeHandle > 0) then
  begin
    // Handle resizing
    case FResizeHandle of
      1: // Top-left
      begin
        NewWidth := FStartRect.Right - FStartRect.Left - DeltaX;
        NewHeight := FStartRect.Bottom - FStartRect.Top - DeltaY;
        NewLeft := FStartRect.Left + DeltaX;
        NewTop := FStartRect.Top + DeltaY;
      end;
      2: // Top-right
      begin
        NewWidth := FStartRect.Right - FStartRect.Left + DeltaX;
        NewHeight := FStartRect.Bottom - FStartRect.Top - DeltaY;
        NewLeft := FStartRect.Left;
        NewTop := FStartRect.Top + DeltaY;
      end;
      3: // Bottom-left
      begin
        NewWidth := FStartRect.Right - FStartRect.Left - DeltaX;
        NewHeight := FStartRect.Bottom - FStartRect.Top + DeltaY;
        NewLeft := FStartRect.Left + DeltaX;
        NewTop := FStartRect.Top;
      end;
      4: // Bottom-right
      begin
        NewWidth := FStartRect.Right - FStartRect.Left + DeltaX;
        NewHeight := FStartRect.Bottom - FStartRect.Top + DeltaY;
        NewLeft := FStartRect.Left;
        NewTop := FStartRect.Top;
      end;
      else
      begin
        NewWidth := Width;
        NewHeight := Height;
        NewLeft := Left;
        NewTop := Top;
      end;
    end;

    // Apply minimum size constraints
    if (NewWidth >= 50) and (NewHeight >= 40) then
    begin
      SetBounds(NewLeft, NewTop, NewWidth, NewHeight);
      Invalidate;
    end;
  end
  else if FDragging then
  begin
    // Handle dragging
    Left := FStartRect.Left + DeltaX;
    Top := FStartRect.Top + DeltaY;
  end;
end;

procedure TImageOverlay.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);

  FDragging := False;
  FResizing := False;
  FResizeHandle := 0;
  Cursor := crSizeAll;

  // Update our stored size in config
  FConfig.Width := Width;
  FConfig.Height := Height;
end;

procedure TImageOverlay.DblClick;
begin
  inherited DblClick;
  if MessageDlg('Remove this image overlay?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    if Assigned(ImageWizard) then
      ImageWizard.RemoveImageOverlay(Self);
  end;
end;

{ TImageEditorWizard }

constructor TImageEditorWizard.Create;
begin
  inherited Create;
  FImageOverlays := TList.Create;
  FEditorNotifiers := TList.Create;
  FImagesVisible := True;

  RegisterEditorNotifiers;
end;

destructor TImageEditorWizard.Destroy;
var
  i: Integer;
begin
  // Clean up all images first
  RemoveAllImages;

  // Unregister all notifiers before destroying anything else
  UnregisterEditorNotifiers;

  // Clean up lists
  if Assigned(FImageOverlays) then
  begin
    FImageOverlays.Free;
    FImageOverlays := nil;
  end;

  if Assigned(FEditorNotifiers) then
  begin
    // Ensure all notifiers are freed
    for i := 0 to FEditorNotifiers.Count - 1 do
      if Assigned(FEditorNotifiers[i]) then
        TImageEditorNotifier(FEditorNotifiers[i]).Free;
    FEditorNotifiers.Free;
    FEditorNotifiers := nil;
  end;

  inherited Destroy;
end;

function TImageEditorWizard.GetIDString: string;
begin
  Result := 'ImageEditor.Plugin.Enhanced.WithGIF.AnimationSpeed';
end;

function TImageEditorWizard.GetName: string;
begin
  Result := 'Enhanced Image Editor Plugin with GIF Animation Speed Control';
end;

function TImageEditorWizard.GetMenuText: string;
begin
  Result := 'Image Editor Tools (PNG/GIF with Animation Speed)';
end;

function TImageEditorWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

function TImageEditorWizard.GetCurrentSourceEditor: IOTASourceEditor;
var
  ModuleServices: IOTAModuleServices;
  Module: IOTAModule;
  Editor: IOTAEditor;
  i: Integer;
begin
  Result := nil;
  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  Module := ModuleServices.CurrentModule;

  if Assigned(Module) then
  begin
    for i := 0 to Module.ModuleFileCount - 1 do
    begin
      Editor := Module.ModuleFileEditors[i];
      if Supports(Editor, IOTASourceEditor, Result) then
        Break;
    end;
  end;
end;

function TImageEditorWizard.GetCurrentEditView: IOTAEditView;
var
  SourceEditor: IOTASourceEditor;
begin
  Result := nil;
  SourceEditor := GetCurrentSourceEditor;
  if Assigned(SourceEditor) and (SourceEditor.EditViewCount > 0) then
    Result := SourceEditor.EditViews[0];
end;

procedure TImageEditorWizard.Execute;
begin
  ShowImageConfigDialog;
end;

procedure TImageEditorWizard.ShowImageConfigDialog;
var
  Config: TImageConfig;
  EditView: IOTAEditView;
  CursorPos: TOTAEditPos;
begin
  EditView := GetCurrentEditView;
  if not Assigned(EditView) then
  begin
    ShowMessage('No source editor window is active');
    Exit;
  end;

  CursorPos := EditView.CursorPos;

  Config.ImagePath := '';
  Config.Width := 200;
  Config.Height := 150;
  Config.StretchMode := ismProportional;
  Config.Transparency := 0;
  Config.SendToBack := True;
  Config.BlendMode := 'Normal';
  Config.ShowBorder := False;
  Config.BorderColor := clGray;
  Config.BackgroundColor := clWhite;
  Config.UseBackground := False;
  Config.EnableAnimation := True; // Enable GIF animation by default
  Config.AnimationSpeed := 100;   // 100ms default animation speed

  if TfrmImageConfig.ShowConfigDialog(Config) then
  begin
    AddImageToEditor(Config, CursorPos.Line, CursorPos.Col);
  end;
end;

procedure TImageEditorWizard.AddImageToEditor(const AConfig: TImageConfig; Line, Column: Integer);
var
  SourceEditor: IOTASourceEditor;
  EditWindow: INTAEditWindow;
  EditControl: TWinControl;
  ImageOverlay: TImageOverlay;
  i: Integer;
begin
  SourceEditor := GetCurrentSourceEditor;
  if not Assigned(SourceEditor) then Exit;

  if SourceEditor.EditViewCount > 0 then
  begin
    if Supports(SourceEditor.EditViews[0], INTAEditWindow, EditWindow) then
    begin
      // Try to find the editor control by name first
      EditControl := EditWindow.Form.FindComponent('Editor') as TWinControl;

      // If not found, look for TEditorControl by class
      if not Assigned(EditControl) then
      begin
        for i := 0 to EditWindow.Form.ComponentCount - 1 do
        begin
          if EditWindow.Form.Components[i].ClassName = 'TEditorControl' then
          begin
            EditControl := EditWindow.Form.Components[i] as TWinControl;
            Break;
          end;
        end;
      end;

      // If still not found, use the form itself
      if not Assigned(EditControl) then
        EditControl := EditWindow.Form;

      if Assigned(EditControl) then
      begin
        ImageOverlay := TImageOverlay.Create(EditControl);
        ImageOverlay.Parent := EditControl;
        ImageOverlay.LoadImage(AConfig.ImagePath, AConfig);
        ImageOverlay.SetPosition(Line, Column);
        ImageOverlay.Visible := FImagesVisible;

        if AConfig.SendToBack then
          ImageOverlay.SendToBack;

        FImageOverlays.Add(ImageOverlay);
      end;
    end;
  end;
end;

procedure TImageEditorWizard.RemoveAllImages;
var
  i: Integer;
  Overlay: TImageOverlay;
begin
  if not Assigned(FImageOverlays) then Exit;

  for i := FImageOverlays.Count - 1 downto 0 do
  begin
    Overlay := TImageOverlay(FImageOverlays[i]);
    if Assigned(Overlay) then
    begin
      try
        Overlay.Parent := nil; // Remove from parent first
        Overlay.Free;
      except
        // Ignore cleanup errors during shutdown
      end;
    end;
  end;
  FImageOverlays.Clear;
end;

procedure TImageEditorWizard.RemoveImageOverlay(AOverlay: TImageOverlay);
begin
  if FImageOverlays.IndexOf(AOverlay) >= 0 then
  begin
    FImageOverlays.Remove(AOverlay);
    AOverlay.Free;
  end;
end;

procedure TImageEditorWizard.ToggleImageVisibility;
var
  i: Integer;
begin
  FImagesVisible := not FImagesVisible;
  for i := 0 to FImageOverlays.Count - 1 do
  begin
    TImageOverlay(FImageOverlays[i]).Visible := FImagesVisible;
  end;
end;

procedure TImageEditorWizard.RegisterEditorNotifiers;
var
  ModuleServices: IOTAModuleServices;
  Module: IOTAModule;
  Editor: IOTAEditor;
  Notifier: TImageEditorNotifier;
  i, j: Integer;
begin
  UnregisterEditorNotifiers;

  if Supports(BorlandIDEServices, IOTAModuleServices, ModuleServices) then
  begin
    for i := 0 to ModuleServices.ModuleCount - 1 do
    begin
      Module := ModuleServices.Modules[i];
      if Assigned(Module) then
      begin
        for j := 0 to Module.ModuleFileCount - 1 do
        begin
          Editor := Module.ModuleFileEditors[j];
          if Assigned(Editor) and Supports(Editor, IOTASourceEditor) then
          begin
            Notifier := TImageEditorNotifier.Create(Self, Editor);
            FEditorNotifiers.Add(Notifier);
          end;
        end;
      end;
    end;
  end;
end;

procedure TImageEditorWizard.UnregisterEditorNotifiers;
var
  i: Integer;
  Notifier: TImageEditorNotifier;
begin
  if not Assigned(FEditorNotifiers) then Exit;

  for i := FEditorNotifiers.Count - 1 downto 0 do
  begin
    Notifier := TImageEditorNotifier(FEditorNotifiers[i]);
    if Assigned(Notifier) then
    begin
      try
        Notifier.MarkEditorInvalid;
        Notifier.Free;
      except
        // Ignore cleanup errors during shutdown
      end;
    end;
  end;
  FEditorNotifiers.Clear;
end;

{ TImageEditorNotifier }

constructor TImageEditorNotifier.Create(AWizard: TImageEditorWizard; AEditor: IOTAEditor);
begin
  inherited Create;
  FWizard := AWizard;
  FEditor := AEditor;
  FEditorValid := True;
  FNotifierIndex := -1;

  if Assigned(FEditor) then
    FNotifierIndex := FEditor.AddNotifier(Self);
end;

destructor TImageEditorNotifier.Destroy;
begin
  if FEditorValid and Assigned(FEditor) and (FNotifierIndex >= 0) then
  begin
    try
      FEditor.RemoveNotifier(FNotifierIndex);
    except
      // Ignore errors during IDE shutdown
    end;
  end;

  // Clear all references
  FEditor := nil;
  FWizard := nil;
  FNotifierIndex := -1;
  FEditorValid := False;

  inherited Destroy;
end;

procedure TImageEditorNotifier.Destroyed;
begin
  MarkEditorInvalid;
  inherited Destroyed;
end;

procedure TImageEditorNotifier.MarkEditorInvalid;
begin
  FEditorValid := False;
  FEditor := nil;
  FNotifierIndex := -1;
end;

procedure TImageEditorNotifier.ViewActivated(const View: IOTAEditView);
begin
  // Clean implementation without refresh glitches
end;

procedure TImageEditorNotifier.ViewNotification(const View: IOTAEditView; Operation: TOperation);
begin
  // Clean implementation without refresh glitches
end;

initialization

finalization
  if (ImageWizardIndex >= 0) and Assigned(BorlandIDEServices) then
  begin
    try
      (BorlandIDEServices as IOTAWizardServices).RemoveWizard(ImageWizardIndex);
    except
      // Ignore errors during IDE shutdown
    end;
    ImageWizardIndex := -1;
  end;

  if Assigned(ImageWizard) then
  begin
    try
      ImageWizard.Free;
    except
      // Ignore errors during shutdown
    end;
    ImageWizard := nil;
  end;

end.
