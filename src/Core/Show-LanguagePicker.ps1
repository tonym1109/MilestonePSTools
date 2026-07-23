function Show-LanguagePicker {
    Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue

    $xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Milestone Toolkit"
        Width="360" SizeToContent="Height"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Background="#1E1E2E" FontFamily="Segoe UI">
    <StackPanel Margin="32,28,32,28">

        <Border Width="48" Height="48" Background="#89B4FA" CornerRadius="10"
                HorizontalAlignment="Center" Margin="0,0,0,16">
            <TextBlock Text="M" FontSize="26" FontWeight="Bold" Foreground="#1E1E2E"
                       HorizontalAlignment="Center" VerticalAlignment="Center"/>
        </Border>

        <TextBlock x:Name="TxtTitle" Text="Milestone Toolkit"
                   FontSize="18" FontWeight="Bold" Foreground="#CDD6F4"
                   HorizontalAlignment="Center" Margin="0,0,0,6"/>

        <TextBlock x:Name="TxtSubtitle" Text="Select language / Choisir la langue"
                   FontSize="12" Foreground="#6C7086"
                   HorizontalAlignment="Center" Margin="0,0,0,24"/>

        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
            <Button x:Name="BtnFR" Width="130" Height="44" Margin="0,0,12,0"
                    Background="#313244" BorderBrush="#45475A" BorderThickness="1"
                    Cursor="Hand">
                <Button.Template>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="8" Padding="12,8">
                            <StackPanel HorizontalAlignment="Center">
                                <TextBlock Text="FR" FontSize="20" FontWeight="Bold"
                                           Foreground="#CDD6F4" HorizontalAlignment="Center"/>
                                <TextBlock Text="Francais" FontSize="11" Foreground="#A6ADC8"
                                           HorizontalAlignment="Center" Margin="0,2,0,0"/>
                            </StackPanel>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#45475A"/>
                                <Setter TargetName="bd" Property="BorderBrush" Value="#89B4FA"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#585B70"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Button.Template>
            </Button>

            <Button x:Name="BtnEN" Width="130" Height="44"
                    Background="#313244" BorderBrush="#45475A" BorderThickness="1"
                    Cursor="Hand">
                <Button.Template>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="8" Padding="12,8">
                            <StackPanel HorizontalAlignment="Center">
                                <TextBlock Text="EN" FontSize="20" FontWeight="Bold"
                                           Foreground="#CDD6F4" HorizontalAlignment="Center"/>
                                <TextBlock Text="English" FontSize="11" Foreground="#A6ADC8"
                                           HorizontalAlignment="Center" Margin="0,2,0,0"/>
                            </StackPanel>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#45475A"/>
                                <Setter TargetName="bd" Property="BorderBrush" Value="#89B4FA"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#585B70"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Button.Template>
            </Button>
        </StackPanel>

        <TextBlock Text="Made by Vincent Le Bonhomme"
                   FontSize="10" Foreground="#45475A"
                   HorizontalAlignment="Center" Margin="0,20,0,0"/>

    </StackPanel>
</Window>
'@

    $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
    $win    = [System.Windows.Markup.XamlReader]::Load($reader)

    $win.FindName('BtnFR').Add_Click({
        $win.Tag = 'fr'
        $win.DialogResult = $true
    })

    $win.FindName('BtnEN').Add_Click({
        $win.Tag = 'en'
        $win.DialogResult = $true
    })

    # Titre dynamique depuis la version centralisee
    $appVer = if ($script:AppVersion) { $script:AppVersion } else { '' }
    $win.Title = if ($appVer) { "Milestone Toolkit $appVer" } else { 'Milestone Toolkit' }

    [void]$win.ShowDialog()

    if ($win.Tag) { return [string]$win.Tag }
    return 'fr'
}
