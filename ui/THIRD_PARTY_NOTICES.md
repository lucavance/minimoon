# Minimoon UI provenance

This module adapts public component capabilities and visual recipes from RUI 0.1.1,
Rabbita 0.15.6 commit b1291945fd0201a0b5b39513b88585d6122db7bc (2026-09-05).
Source: https://github.com/moonbit-community/rabbita/tree/b1291945fd0201a0b5b39513b88585d6122db7bc/rui
The native MiniApp implementation does not import Rabbita's browser runtime.
The module LICENSE retains the original RUI MIT notice. The source mapping is
maintained in the [native migration map](https://github.com/lucavance/minimoon/blob/main/ui/docs/migration.md).
Minimoon core retains its separate Apache-2.0 license.

# Third-party notices

The following upstream description and license notices are retained from the
pinned RUI source. Its HTML/browser description refers to upstream RUI, not
to this native Minimoon implementation.

Rabbita UI translates visual recipes and public component conventions from
shadcn/ui's Vega style. Calendar focus behavior additionally follows React
DayPicker, which shadcn/ui wraps. The MoonBit implementation is original and
uses Rabbita-native HTML, ARIA, browser primitives, and incremental state.

## shadcn/ui

MIT License

Copyright (c) 2023 shadcn

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## React DayPicker

The MIT License (MIT)

Copyright (c) 2014-2025 Giampaolo Bellavite <io@gpbl.dev> and contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
