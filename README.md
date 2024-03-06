# 音乐专辑管理脚本

## 目录结构

```
歌手名 (备注)
├── 日期 - (系列/备注) 专辑名 (类型)
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

## CUE分割 - [split-album.sh](split-album.sh)

[split-album.sh](split-album.sh)主要用于将CUE母片分割成单独的歌曲文件，**要求CUE文件和数据文件的名称必须相同。**

[split-album.sh](split-album.sh)始终使用`flac`格式来保存原始歌曲，因其支持的音频格式多，可以不经转码直接从母片转换过来。

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

## 更新文件名及标签信息 - [update-index.sh](update-index.sh)

[update-index.sh](update-index.sh)主要用于原始歌曲管理，可用于：

1. 更新文件名（参考[输出格式](### 输出格式)）
2. 写入标签信息

### 依赖

```shell
#1. Ubuntu 
sudo apt install ffmpeg

#2. macOS
brew install ffmpeg
```

### 环境变量

* RUN           : 是否执行真正的命令（默认为0），主要用于检查输出是否正确。
* ARTIST        : 强制专辑歌手名称（默认为空）。
~~* TITLE_ARTIST  : 文件名是否包含歌手名（默认为0）。~~
* UPDATE_ARTIST : 是否更新歌曲标签信息（默认为0）。
* ARTIST_TITLE  : 歌手名是否在歌曲名前面（默认为0），主要用于处理特殊文件，不影响`update-index.sh`的输出。

注意：

~~1. `UPDATE_ARTIST=0`时，如果`TITLE_ARTIST=0`，依然会更新标签信息。~~
2. `UPDATE_ARTIST=1`时，文件中的标签信息会被忽略，可用于更新标签信息，也可用于更正错误的标签信息。
3. 所有环境变量可以叠加使用。

### 使用方法

```shell
#1. 仅更新文件名
./update-index.sh /path/to/专辑/*.flac

#2. 仅更新文件名（歌手名）
~~TITLE_ARTIST=1 ./update-index.sh /path/to/专辑/*.flac~~

#3. 更新文件名和标签信息
UPDATE_ARTIST=1 ./update-index.sh /path/to/专辑/*.flac

#4. 特殊文件处理：歌手名 - 歌曲名
ARTIST_TITLE=1 ./update-index.sh /path/to/专辑/*.flac

#5. 合并多个CD
./update-index.sh /path/to/专辑CD1/*.flac /path/to/专辑CD2/*.flac
```

**测试无误后，`export RUN=1`再执行以上命令即可实现更改。**

### 输入格式

* 歌曲名.flac
* 01 - 歌曲名.flac
* 01 - 歌曲名 - 歌手名.flac
* 01 - 歌曲名 - 歌手1&歌手2.flac

* 01.歌曲名.flac
* 01.歌曲名(歌手名).flac
* 01.歌曲名(歌手1&歌手2).flac
* 01.歌曲名『备注』(歌手1&歌手2).flac

### 输出格式

* 01.歌曲名(歌手1&歌手2).flac

### 进阶

#### [artist.sed](artist.sed)

由于歌手名存在中文、繁体、英文、大小写、别名、曾用名等情况，所以我们需要将不同情况统一转换成自己的偏好，[artist.sed](artist.sed)应运而生。

[artist.sed](artist.sed)支持`sed`语法：

```sed
s@鄧麗君@邓丽君@g       # 繁体
s@王靖雯@王菲@g         # 曾用名
s@Faye Wong@王菲@g      # 英文
```

#### [title.sed](title.sed) & [private.sed]()

主要用于处理原始歌曲文件中的特殊字符，增强[update-index.sh](update-index.sh)的兼容性，也可用于歌曲名的翻译等。同样[title.sed](title.sed)也支持`sed`语法。

同时，[update-index.sh](update-index.sh)还支持歌手或专辑的[private.sed]()，只要将其放置在歌手或专辑文件夹中即可。

```sed
s/(\s*\([0-9]\{4\}\)\s*)//g     # 删除如'(2008)'等年份字符
# 语言
s/(英文)/『英』/g
s/(国语版)/『国』/g
```
