$YourDirToCompress="."
$ZipFileResult=".\SNKRX.zip"
$LoveFileResult=".\SNKRX.love"
$DirToExclude=@(".git")

Remove-Item $LoveFileResult -ErrorAction Ignore

Get-ChildItem $YourDirToCompress  | 
           where { $_.Name -notin $DirToExclude} | 
              Compress-Archive -DestinationPath $ZipFileResult -CompressionLevel Fastest -Update
              
Rename-Item -Path $ZipFileResult -NewName $LoveFileResult