object frmImageConfig: TfrmImageConfig
  Left = 0
  Top = 0
  Caption = 'Configure Image Overlay'
  ClientHeight = 680
  ClientWidth = 480
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 13
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 480
    Height = 630
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object grpImageFile: TGroupBox
      Left = 8
      Top = 8
      Width = 464
      Height = 60
      Caption = ' Image File '
      TabOrder = 0
      object lblImagePath: TLabel
        Left = 12
        Top = 20
        Width = 53
        Height = 13
        Caption = 'Image File:'
      end
      object edtImagePath: TEdit
        Left = 12
        Top = 36
        Width = 360
        Height = 21
        TabOrder = 0
        OnChange = edtImagePathChange
      end
      object btnBrowse: TButton
        Left = 380
        Top = 34
        Width = 70
        Height = 25
        Caption = 'Browse...'
        TabOrder = 1
        OnClick = btnBrowseClick
      end
    end
    object grpSize: TGroupBox
      Left = 8
      Top = 76
      Width = 224
      Height = 120
      Caption = ' Size Settings '
      TabOrder = 1
      object lblWidth: TLabel
        Left = 12
        Top = 24
        Width = 32
        Height = 13
        Caption = 'Width:'
      end
      object lblHeight: TLabel
        Left = 12
        Top = 52
        Width = 35
        Height = 13
        Caption = 'Height:'
      end
      object edtWidth: TSpinEdit
        Left = 60
        Top = 20
        Width = 80
        Height = 22
        MaxValue = 1000
        MinValue = 20
        TabOrder = 0
        Value = 200
        OnChange = edtWidthChange
      end
      object edtHeight: TSpinEdit
        Left = 60
        Top = 48
        Width = 80
        Height = 22
        MaxValue = 1000
        MinValue = 20
        TabOrder = 1
        Value = 150
        OnChange = edtHeightChange
      end
      object chkMaintainAspect: TCheckBox
        Left = 12
        Top = 80
        Width = 140
        Height = 17
        Caption = 'Maintain Aspect Ratio'
        Checked = True
        State = cbChecked
        TabOrder = 2
        OnClick = chkMaintainAspectClick
      end
    end
    object grpAppearance: TGroupBox
      Left = 240
      Top = 76
      Width = 232
      Height = 120
      Caption = ' Appearance '
      TabOrder = 2
      object lblStretchMode: TLabel
        Left = 12
        Top = 24
        Width = 68
        Height = 13
        Caption = 'Stretch Mode:'
      end
      object lblTransparency: TLabel
        Left = 12
        Top = 56
        Width = 70
        Height = 13
        Caption = 'Transparency:'
      end
      object lblTransValue: TLabel
        Left = 135
        Top = 90
        Width = 79
        Height = 13
        Caption = '0% Transparent'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object cmbStretchMode: TComboBox
        Left = 90
        Top = 20
        Width = 130
        Height = 21
        Style = csDropDownList
        TabOrder = 0
        OnChange = cmbStretchModeChange
      end
      object trkTransparency: TTrackBar
        Left = 90
        Top = 48
        Width = 130
        Height = 28
        Max = 255
        TabOrder = 1
        OnChange = trkTransparencyChange
      end
      object chkSendToBack: TCheckBox
        Left = 12
        Top = 88
        Width = 120
        Height = 17
        Caption = 'Send to Background'
        Checked = True
        State = cbChecked
        TabOrder = 2
      end
    end
    object grpBorder: TGroupBox
      Left = 8
      Top = 204
      Width = 224
      Height = 80
      Caption = ' Border Settings '
      TabOrder = 3
      object lblBorderColor: TLabel
        Left = 12
        Top = 48
        Width = 64
        Height = 13
        Caption = 'Border Color:'
        Enabled = False
      end
      object chkShowBorder: TCheckBox
        Left = 12
        Top = 24
        Width = 97
        Height = 17
        Caption = 'Show Border'
        TabOrder = 0
        OnClick = chkShowBorderClick
      end
      object pnlBorderColor: TPanel
        Left = 80
        Top = 44
        Width = 50
        Height = 20
        Color = clGray
        Enabled = False
        ParentBackground = False
        TabOrder = 1
        OnClick = pnlBorderColorClick
      end
    end
    object grpBackground: TGroupBox
      Left = 8
      Top = 292
      Width = 224
      Height = 80
      Caption = ' Background Settings '
      TabOrder = 4
      object lblBackgroundColor: TLabel
        Left = 12
        Top = 48
        Width = 88
        Height = 13
        Caption = 'Background Color:'
        Enabled = False
      end
      object chkUseBackground: TCheckBox
        Left = 12
        Top = 24
        Width = 130
        Height = 17
        Caption = 'Use Background Color'
        TabOrder = 0
        OnClick = chkUseBackgroundClick
      end
      object pnlBackgroundColor: TPanel
        Left = 110
        Top = 44
        Width = 50
        Height = 20
        Color = clWhite
        Enabled = False
        ParentBackground = False
        TabOrder = 1
        OnClick = pnlBackgroundColorClick
      end
    end
    object grpAnimation: TGroupBox
      Left = 8
      Top = 380
      Width = 224
      Height = 120
      Caption = ' GIF Animation Settings '
      TabOrder = 5
      object lblAnimationSpeed: TLabel
        Left = 12
        Top = 56
        Width = 84
        Height = 13
        Caption = 'Animation Speed:'
        Enabled = False
      end
      object lblSpeedValue: TLabel
        Left = 140
        Top = 80
        Width = 34
        Height = 13
        Caption = '100 ms'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblSpeedHint: TLabel
        Left = 12
        Top = 96
        Width = 123
        Height = 13
        Caption = 'Lower = Faster animation'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object chkEnableAnimation: TCheckBox
        Left = 12
        Top = 24
        Width = 130
        Height = 17
        Caption = 'Enable GIF Animation'
        Checked = True
        State = cbChecked
        TabOrder = 0
        OnClick = chkEnableAnimationClick
      end
      object trkAnimationSpeed: TTrackBar
        Left = 12
        Top = 72
        Width = 120
        Height = 20
        Max = 1000
        Min = 10
        Position = 100
        TabOrder = 1
        OnChange = trkAnimationSpeedChange
      end
    end
    object grpPreview: TGroupBox
      Left = 240
      Top = 204
      Width = 232
      Height = 296
      Caption = ' Preview '
      TabOrder = 6
      object pnlPreviewBg: TPanel
        Left = 12
        Top = 20
        Width = 208
        Height = 264
        BevelOuter = bvLowered
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        object imgPreview: TImage
          Left = 1
          Top = 1
          Width = 206
          Height = 262
          Align = alClient
          Center = True
          Proportional = True
          Stretch = True
          Transparent = True
        end
      end
    end
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 630
    Width = 480
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnOK: TButton
      Left = 240
      Top = 12
      Width = 75
      Height = 25
      Caption = 'OK'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 324
      Top = 12
      Width = 75
      Height = 25
      Cancel = True
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = btnCancelClick
    end
    object btnReset: TButton
      Left = 405
      Top = 12
      Width = 67
      Height = 25
      Caption = 'Reset'
      TabOrder = 2
      OnClick = btnResetClick
    end
  end
  object OpenPictureDialog: TOpenPictureDialog
    Filter = 
      'All (*.png;*.jpg;*.jpeg;*.gif;*.bmp)|*.png;*.jpg;*.jpeg;*.gif;*.' +
      'bmp|Portable Network Graphics (*.png)|*.png|JPEG Image File (*.j' +
      'pg)|*.jpg|JPEG Image File (*.jpeg)|*.jpeg|CompuServe GIF Image (' +
      '*.gif)|*.gif|Bitmaps (*.bmp)|*.bmp'
    Left = 96
    Top = 520
  end
  object ColorDialog: TColorDialog
    Left = 336
    Top = 520
  end
end
