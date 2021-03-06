object EditForm: TEditForm
  Left = 0
  Top = 0
  HelpType = htKeyword
  HelpKeyword = 'Edit Merge Window'
  ActiveControl = edName
  Caption = 'Edit Merge'
  ClientHeight = 222
  ClientWidth = 334
  Color = clBtnFace
  Constraints.MaxHeight = 350
  Constraints.MaxWidth = 450
  Constraints.MinHeight = 250
  Constraints.MinWidth = 350
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  DesignSize = (
    334
    222)
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl: TPageControl
    Left = 8
    Top = 8
    Width = 318
    Height = 175
    ActivePage = TabSheet
    Align = alCustom
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
    object TabSheet: TTabSheet
      Caption = 'Edit Merge'
      object lblName: TLabel
        Left = 13
        Top = 13
        Width = 27
        Height = 13
        Margins.Left = 8
        Margins.Top = 8
        Margins.Right = 8
        Margins.Bottom = 8
        Caption = 'Name'
        Transparent = True
      end
      object lblFilename: TLabel
        Left = 13
        Top = 42
        Width = 42
        Height = 13
        Margins.Left = 8
        Margins.Top = 8
        Margins.Right = 8
        Margins.Bottom = 8
        Caption = 'Filename'
      end
      object lblMethod: TLabel
        Left = 13
        Top = 71
        Width = 69
        Height = 13
        Margins.Left = 8
        Margins.Top = 8
        Margins.Right = 8
        Margins.Bottom = 8
        Caption = 'Merge method'
      end
      object lblRenumbering: TLabel
        Left = 13
        Top = 100
        Width = 63
        Height = 13
        Margins.Left = 8
        Margins.Top = 8
        Margins.Right = 8
        Margins.Bottom = 8
        Caption = 'Renumbering'
      end
      object edName: TEdit
        Left = 109
        Top = 12
        Width = 195
        Height = 21
        Hint = 'Warning: Mod folder already exists.'
        Align = alCustom
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 0
        OnChange = edNameChange
        OnKeyDown = edKeyDown
      end
      object edFilename: TEdit
        Left = 109
        Top = 41
        Width = 195
        Height = 21
        Hint = 'Filename invalid.'
        Align = alCustom
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 1
        OnChange = edFilenameChange
        OnEnter = edFilenameEnter
        OnKeyDown = edKeyDown
      end
      object cbMethod: TComboBox
        Left = 109
        Top = 68
        Width = 195
        Height = 21
        Align = alCustom
        Style = csDropDownList
        Anchors = [akLeft, akTop, akRight]
        ItemIndex = 0
        TabOrder = 2
        Text = 'Overrides'
        OnChange = cbMethodChange
        Items.Strings = (
          'Overrides'
          'New records')
      end
      object cbRenumbering: TComboBox
        Left = 109
        Top = 97
        Width = 195
        Height = 21
        Align = alCustom
        Style = csDropDownList
        Anchors = [akLeft, akTop, akRight]
        ItemIndex = 0
        TabOrder = 3
        Text = 'Conflicting'
        Items.Strings = (
          'Conflicting'
          'All')
      end
    end
  end
  object btnOk: TButton
    Left = 170
    Top = 189
    Width = 75
    Height = 25
    Align = alCustom
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 1
    OnClick = btnOkClick
  end
  object btnCancel: TButton
    Left = 251
    Top = 189
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
