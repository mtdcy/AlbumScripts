# 音乐专辑管理脚本

## 更新文件名及标签信息 - [update-index.sh](update-index.sh)

### 依赖

```shell
#1. Ubuntu 
sudo apt install ffmpeg

#2. macOS
brew install ffmpeg
```

### 使用方法

```shell
#1. 仅更新文件名
./update-index.sh /path/to/专辑/*.flac

#2. 仅更新文件名（带歌手名）
TITLE_ARTIST=1 ./update-index.sh /path/to/专辑/*.flac

#3. 更新文件名和标签信息
UPDATE_ARTIST=1 ./update-index.sh /path/to/专辑/*.flac
```

**测试无误后，`export RUN=1`再执行以上命令即可真正实现更改。**

### 输入格式

* 歌曲名.flac
* 01 - 歌曲名.flac
* 01 - 歌曲名 - 歌手名.flac
* 01 - 歌曲名 - 歌手名1&歌手名2.flac

* 01.歌曲名.flac
* 01.歌曲名(歌手名).flac
* 01.歌曲名(歌手名1&歌手名2).flac
* 01.(系列/备注/...)歌曲名(歌手名1&歌手名2).flac

### 输出格式

* 01.歌曲名(歌手名1&歌手名2).flac

