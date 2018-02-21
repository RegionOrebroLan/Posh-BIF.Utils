En powershellmodul för att hantera konfiguration till Ineras Lokala Säkerhetstjänster.


### Snabbguide

Klona repository
```shell
git clone https://github.com/RegionOrebroLan/Posh-BIF.Utils.git
```
Importera modulen
```powershell
Import-Module ./Posh-BIF.Utils
```
Initiera konfigurationsfil med inställningar för en testmiljö och produktionsmiljö.
Ändra x:\BIF\config\ till den sökväg där filerna skall lagras.
```powershell
Initialize-BIFSettings -ConfigReferences @{Test="x:\BIF\config\test.conf"; Prod="x:\BIF\config\prod.conf"}
Use-BIFSettings
```

Lägg till en kund, vårdgivare samt vårdsystem.
```powershell
Add-BIFCustomer -CustomerName "Customer name 1" -ShortName "Cust1" -Environment Test
Add-BIFCareProvider -CustomerName "Customer name 1" -CareProviderName "Careprovider" -CareProviderHSAId "SE232xxxxxxx-1234" -Environment Test
Add-BIFSystem -CustomerName "Customer name 1" -SystemName "System1" -SystemHSAId "SE232xxxxxx-ABCD" -Environment Test
```

Skapa regel-filer för inläsning i Lokala säkerhetstjänster.
```powershell
Publish-BIFSystemAccessData -Environment Test
Publish-BIFUserAccessData -Environment Test
```
