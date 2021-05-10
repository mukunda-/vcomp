#-----------------------------------------------------------------------------------------
# vcomp.ps1
# - Handy video compression presets for your everyday screen recordings.
# Author: Mukunda Johnson
# Version: 1.1 (5/9/2021)
# License: MIT
#-----------------------------------------------------------------------------------------
<#PSScriptInfo

.VERSION 1.1

.GUID 203a3186-d66b-4f22-99f7-b6146385d4ba

.AUTHOR Mukunda Johnson (mukunda@mukunda.com)

.COMPANYNAME

.COPYRIGHT (C) 2021 Mukunda Johnson

.TAGS ffmpeg video compression render

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<# 

.DESCRIPTION 
  Handy video compression presets for your everyday screen recordings. 

.PARAMETER InputFile
  Video file to process.

.PARAMETER Quality
  Quality preset to use. See the options when you run the script.

.PARAMETER OutputFile
  Path to the output file to write. The extension may decide the format.

.Parameter TrimStart
  If specified, will skip to this point in the input file before rendering.
  Typically specified in MM:SS format. This is passed directly to ffmpeg.
  See https://ffmpeg.org/ffmpeg-utils.html#time-duration-syntax

.Parameter TrimEnd
  If specified, will not render past this point.
  Typically specified in MM:SS format. This is passed directly to ffmpeg.
  See https://ffmpeg.org/ffmpeg-utils.html#time-duration-syntax

.Parameter AdditionalFfmpegOptions
  Options that are passed directly to ffmpeg.

#>
param(
    [string]$InputFile,
    [int]$Quality,
    [string]$OutputFile,
    [string]$TrimStart,
    [string]$TrimEnd,
    [string[]]$AdditionalFfmpegOptions
)


#-----------------------------------------------------------------------------------------
# Checks variable for a value and then fetches it if needed. Default value is provided if
#  the user skips the option. $helpScript is an optional scriptblock to print help before
#  the prompt.
Function GetParam( [ref][string]$Variable, [string]$name, [string]$prompt,
                   [string]$default = "", [scriptblock]$helpScript ) {
   if( -not $Variable.Value ) {

      if( $helpScript ) {
         Invoke-Command -ScriptBlock $helpScript
      }

      $defaultText = $default
      if( -not $default ) {
         $defaultText = "None"
      }
      $Variable.Value = (Read-Host -Prompt "$prompt [$defaultText]").Trim()
      if( $Variable.Value -eq "" ) {
         $Variable.Value = $default
      }
   } else {
      Write-Host "*** $name is $($Variable.Value)."
   }
}

Function PromptWithDefault( [string]$prompt, [string]$default ) {
   $value = (Read-Host -Prompt "$prompt [$default]").Trim()
   if( $value -eq "" ) {
      return $default
   }
   
   return $value
}

Function PostfixFilename( [string]$path, $postfix ) {
   $dot = $path.LastIndexOf( "." )
   if( $dot -eq -1 ) { $dot = $path.Count }
   $path.Substring( 0, $dot ) + $postfix + $path.Substring( $dot )
}

Write-Host "-------------------------------------------------------------------------------"
GetParam ([ref]$InputFile) "Input file" "Path to input file" "input.mp4"

$outputFileDefault = PostfixFilename $InputFile "-vc"
GetParam ([ref]$OutputFile) "Output file" "Path to output file" $outputFileDefault

GetParam ([ref]$Quality) "Video quality" "Video quality" "1" {
   Write-Host "-------------------------------------------------------------------------------"
   Write-Host "*** Select output video quality."
   Write-Host " (1) OK - 32kbps audio / 35 crf / 20 fps / ~1.2mb per minute"
   Write-Host "     This provides comprehensible video and audio with a lesser visual"          -ForegroundColor green
   Write-Host "     experience. Good for compressing long recordings."                          -ForegroundColor green
   Write-Host " (2) BETTER - 48kbps audio / 30 crf / 25 fps / ~2.0mb per minute"
   Write-Host "     This provides crisper video and audio, suitable for less"                   -ForegroundColor green
   Write-Host "     common videos such as defect reproductions."                                -ForegroundColor green
   Write-Host " (3) BEST - 64kbps audio / 25 crf / 30 fps / ~3.2mb per minute"
   Write-Host "     Great video and voice, these are best if the video is customer-facing, but" -ForegroundColor green
   Write-Host "     these settings should still result in a relatively small file size in"      -ForegroundColor green
   Write-Host "     comparison to an 'HD' video."                                               -ForegroundColor green
   Write-Host " (4) CUSTOM"
   Write-Host "     Enter parameters manually."                                                 -ForegroundColor green
}

switch( $Quality ) {
   1 {
      $codec_options = @{
         audio          = "32k"
         crf            = "35"
         audio_channels = 1
         maxfps         = 20
      }
   }
   2 {
      $codec_options = @{
         audio          = "48k"
         crf            = "30"
         audio_channels = 1
         maxfps         = 25
      }
   }
   3 {
      $codec_options = @{
         audio          = "64k"
         crf            = "25"
         audio_channels = 1
         maxfps         = 30
      }
   }
   4 {
      $codec_options = @{}
      Write-Host "*** Enter Custom Render Settings" -ForegroundColor black -BackgroundColor Yellow
      $codec_options.audio          = PromptWithDefault "- Audio rate (32k-192k)" "64k"
      $codec_options.audio_channels = PromptWithDefault "- Audio Channels (1-2)" "1"
      $codec_options.crf            = PromptWithDefault "- CRF (0-51)" "25"
      $codec_options.maxfps         = PromptWithDefault "- Max FPS (5-120)" "30"
      
   }
   default {
      Write-Host "*** [Error] Unknown quality setting." -ForegroundColor red
      exit
   }
}

# TODO: Validate the quality settings.

GetParam ([ref]$TrimStart) "Trim start" "Trim start point"
GetParam ([ref]$TrimEnd) "Trim end" "Trim end point"

if( -not $AdditionalFfmpegOptions ) {
   $AdditionalFfmpegOptions = @()
}

Function Get-Video-FPS( [string]$path ) {
   
   # Use ffprobe to fetch the stream data from the source file. We can output it as JSON
   #  and parse that.
   $video_info = ffprobe -v quiet -show_streams -of json $path | ConvertFrom-JSON
   if( -not $video_info ) {
      return $null
   }
   $fps = $null
   foreach( $stream in $video_info.streams ) {
      # Find the video stream and extract the input FPS.
      # Not sure if there is a better/safer way to determine this. Might not produce
      #  expected results with some video files. Typically the "avg_frame_rate" is in
      #  a format of "a/b", i.e., expressed as a ratio.
      if( $stream.codec_type -eq "video" ) {
         $fps = $stream.avg_frame_rate -split "/"
         if( $fps.Count -eq 2 ) {
            $fps = [float]$fps[0] / [float]$fps[1]
         } elseif( $fps.Count -eq 1 ) {
            # I confirmed that powershell won't do something stupid like not return an
            #  array if there is only one term.
            $fps = $fps[0]
         } else {
            Write-Host "*** [Error] Error while reading source file info." -ForegroundColor red
            return $null
         }
         break
      }
   }
   return $fps
}

$fps = Get-Video-FPS $InputFile
if( -not $fps ) {
   Write-Host "*** [Error] Couldn't read stream data from source file." -ForegroundColor red
   exit
}

$render_options = "-b:a", $codec_options.audio,
                  "-ac", $codec_options.audio_channels,
                  "-crf", $codec_options.crf

# If the FPS is already lower than the max FPS, then we don't want to do anything with
#  the FPS. Just leave it as is.
# Add a little extra tolerance, because slightly lowering FPS might have adverse effects.
if( $fps -gt $codec_options.maxfps * 1.01 ) {
   $opt = ("fps=$($codec_options.maxfps):round=near")
   $render_options += "-filter:v", $opt
}

Write-Host "*** Rendering output to $OutputFile." -ForegroundColor Yellow

$trim = @()
if( $TrimStart ) {
   $trim += "-ss", $TrimStart
}

if( $TrimEnd ) {
   $trim += "-to", $TrimEnd
}

Write-Host ">> ffmpeg" "-y" @trim "-i" $InputFile @render_options @AdditionalFfmpegOptions $OutputFile -separator " "

# Placing the trim parameters (-ss/-to) before the input file causes the seek to happen
#  before decoding. It will skip to a keyframe and then decode only a small offset.
ffmpeg -y @trim -i $InputFile @render_options @AdditionalFfmpegOptions $OutputFile
