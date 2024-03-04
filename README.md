# 音乐专辑管理脚本

## 目录结构

```
歌手名（备注）
├── 日期 - 专辑名（备注）
│   ├── 01.歌曲名(歌手1&歌手2).m4a


# 比如：
周杰伦
├── 2016.05.10 - 魔天伦世界巡回演唱会
│   ├── 01.惊叹号Live(周杰伦).m4a
│   ├── 02.龙拳Live(周杰伦).m4a
│   ├── 03.最后的战役Live(周杰伦).m4a
│   ├── 04.天台Live(周杰伦&宋健彰).m4a
│   ├── 05.比较大的大提琴Live(周杰伦&华语群星).m4a
│   ├── 06.快门慢舞Live(周杰伦&袁咏琳&邱凯伟).m4a
```

## CD/CUE分割 - [split-album.sh](split-album.sh)

### 依赖

```shell
#1. Ubuntu 
sudo apt install ffmpeg cuetools shntool flac

#2. macOS
brew install ffmpeg cuetools shntool flac
```

### 使用方法

```shell
#1. 指定专辑目录
./split-album.sh /path/to/专辑

#2. 指定专辑cue
./split-album.sh /path/to/专辑.cue
```

**默认总是分割成flac文件。**

**cue文件和数据文件的名称必须相同。**


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

#4. 特殊文件处理：歌手名 - 歌曲名
ARTIST_TITLE=1 ./update-index.sh /path/to/专辑/*.flac

#5. 合并多个CD
./update-index.sh /path/to/专辑CD1/*.flac /path/to/专辑CD2/*.flac
```

**测试无误后，`export RUN=1`再执行以上命令即可真正实现更改。**

**所有环境变量可以叠加使用。**

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

