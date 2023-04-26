import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../states/theme_state.dart';
import '../../utils/font_manager.dart';

class FontSettingPage extends StatefulWidget {
  const FontSettingPage({Key? key}) : super(key: key);

  @override
  State<FontSettingPage> createState() => _FontSettingPageState();
}

class _FontSettingPageState extends State<FontSettingPage> {
  List<String> _fontNameList = []; // 字体名称列表

  // 初始化字体名称列表
  Future<void> initData() async {
    await readAllFont().then(
      (value) => setState(() => _fontNameList = value),
    );
  }

  @override
  void initState() {
    super.initState();
    initData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('应用字体'),
        actions: [
          // 说明对话框
          IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('说明'),
                content: const Text('仅支持导入 otf/ttf/ttc 格式的字体文件'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('确定'),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.help_outline),
          ),
          // 添加字体
          IconButton(
            onPressed: () async {
              // 从本地文件导入字体
              await loadLocalFont();
              // 重新初始化字体名称列表
              await initData();
            },
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          itemCount: _fontNameList.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return RadioListTile(
                value: '默认字体',
                groupValue: context.watch<ThemeState>().themeFont,
                title: const Text(
                  '默认字体',
                  style: TextStyle(fontFamily: '默认字体'),
                ),
                onChanged: (value) {
                  if (value != null) {
                    context.read<ThemeState>().setThemeFontState(value);
                  }
                },
              );
            }
            if (index == _fontNameList.length + 1) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Text('* 点击右上角导入字体\n* 仅支持 otf/ttf/ttc 格式的字体文件'),
              );
            }
            return RadioListTile(
              value: _fontNameList[index - 1],
              groupValue: context.watch<ThemeState>().themeFont,
              title: Text(
                _fontNameList[index - 1].split('.').first,
                style: TextStyle(fontFamily: _fontNameList[index - 1]),
              ),
              onChanged: (value) {
                if (value != null) {
                  context.read<ThemeState>().setThemeFontState(value);
                }
              },
              secondary: IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('删除确认'),
                      content: Text(
                        '确认删除字体：${_fontNameList[index - 1]}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () async {
                            if (context.read<ThemeState>().themeFont ==
                                _fontNameList[index - 1]) {
                              context
                                  .read<ThemeState>()
                                  .setThemeFontState('思源黑体');
                            }
                            // 删除字体
                            await deleteFont(_fontNameList[index - 1]);
                            // 重新初始化字体名称列表
                            await initData();
                            if (!mounted) return;
                            Navigator.pop(context);
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
