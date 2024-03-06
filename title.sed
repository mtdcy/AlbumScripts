# 注意顺序
# remove index
s/^[0-9\.\_\ \-]\+//

# 中文括号 => 英文括号，方便后续统一处理
s/（/ (/g
s/）/) /g

# (日期) => 删除
s/(\ *[0-9]\{4\}\ *)//g

# 特殊字符 '-', 删除与'-'连在一起的'.' ' '
s/[\ \.]*\-\+[\ \.]*/-/g

# (语言)
s/(\(.*\)-\(.*\))/(\1 \2)/g       # replace '-' inside '()'
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
s/(钢琴版)/『钢琴』/g
s/(管弦乐版)/『管弦乐』/g
s/(弦乐版)/『弦乐』/g
s/(Original Version)/『原版』/Ig
s/(\(.*\) Version)/『\1版』/Ig
s/(\(.*\)版\([:：].*\))/『\1版\2』/g
s/(\(.*\)版本\?)/『\1版』/g
s/(Unplugged)/『原音乐』/Ig
s/(Part \(.*\))/\1/Ig
s/(LIVE)/『LIVE』/Ig
s/(LIVE版)/『LIVE』/Ig
s/(KARAOKE VERSION)/『卡拉OK』/Ig
s/(演奏)/『演奏』/g
s/(\(.*\) MIX)/『\1 Mix』/Ig
s/(MIX)/『MIX』/Ig
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
