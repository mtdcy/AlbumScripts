# 输入格式
#   01.(xxx)title(artist1&artist2).flac
#   01 xxx - title - artist1&artist2.flac
#   01 - xxx - title - artist1&artist2.flac
# 输出格式：
#   01.(xxx)title(artist1&artist2).flac

# remove index: '01.' '01 ' '01 - '
s/^[0-9]\+[\.\ \-]*//

# 中文括号 => 英文括号，方便后续统一处理
s/\ *（\ */ (/g
s/\ *）\ */) /g

# 特殊字符 '-', 
s/[\ \.]*\-\+[\ \.]*/-/g        # 删除与'-'连在一起的'.' ' '
s/(\(.*\)\-\+\(.*\))/(\1 \2)/g  # replace '-' inside '()'
# => '()'中的其他字符交给artist.sed处理

# (编号)
s/(\ *\([0-9]\+\)\ *)/『\1』/g

# (语言)
s/(英文)/『英』/g
s/(国语版)/『国』/g
s/(国语)/『国』/g
s/(国)/『国』/g
s/(粤语版)/『粤』/g
s/(粤语)/『粤』/g
s/(粤)/『粤』/g
s/(日本版)/『日』/g
s/(日文)/『日』/g
s/(日)/『日』/g

# (乐器)
s/(钢琴版)/『钢琴』/g
s/(管弦乐版)/『管弦乐』/g
s/(弦乐版)/『弦乐』/g

# 版本
s/(Original Version)/『原版』/Ig
s/(\(.*\) Version)/『\1版』/Ig
s/(\(.*\)版\([:：].*\))/『\1版\2』/g
s/(\(.*\)版本\?)/『\1版』/g
s/(Unplugged)/『原音乐』/Ig
s/(LIVE)/『LIVE』/Ig
s/(LIVE版)/『LIVE』/Ig
s/(KARAOKE VERSION)/『卡拉OK』/Ig
s/(\(.*\) MIX)/『\1 Mix』/Ig
s/(MIX)/『MIX』/Ig

#
s/(Part \(.*\))/\1/Ig
s/(演奏)/『演奏』/g
s/(\(.*\)插曲)/『\1插曲』/g
s/(\(.*\)主题曲)/『\1主题曲』/g
s/(一)/『一』/g
s/(二)/『二』/g
s/(\(.*\)合唱)/『\1合唱』/g
s/(音乐)/『音乐』/g
s/(\(.*\)周年)/『\1周年』/g
s/(REPRISE)/『重演』/Ig
s/(\(.*\)领唱\(.*\)/\1\2/g
s/Di-Dar/Di Dar/g
s/(清唱)/『清唱』/g
s/(\(.*\)演唱会)/『\1演唱会』/g
s/(\(纪念.*$\))/『纪念\1』/g
s/(\(.*\)篇)/『\1篇』/g

# final: remove heading & trailing spaces
s/^\ \+//
s/\ \+$//
