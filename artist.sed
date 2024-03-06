# 中文符号
s@\ *，\ *@\&@g
s@\ *、\ *@\&@g
# 特殊分割符
s@\ *[,\/\-]\+\ *@\&@g      # ',/-' => '&'
s@\&\+@\&@g
s@^\&\+@@

# 
s@劉德華@刘德华@g
s@鄧麗君@邓丽君@g
s@Teresa Teng@邓丽君@Ig
s@王靖雯@王菲@g     # 曾用名
s@叶蒨文@叶倩文@g
s@李龍基@李龙基@g
s@盧業媚@卢业媚@g
s@張國榮@张国荣@g

#
s@Beethoven@贝多芬@Ig
s@BEYOND@Beyond@Ig
s@Faye Wong@王菲@Ig
s@RondoVeneziano@威尼斯韵律乐队@g
s@雅尼@Yanni@g
s@肯尼·\*基@Kenny G@g
s@凯丽金@Kenny G@g

# 
s@羅@罗@g
s@鄭@郑@g
s@羅@罗@g

#
s@群唱@群星@g
