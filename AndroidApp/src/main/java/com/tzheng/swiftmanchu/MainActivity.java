package com.tzheng.swiftmanchu;

import android.app.Activity;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.AdapterView;
import android.widget.BaseAdapter;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.ScrollView;
import android.widget.TextView;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public final class MainActivity extends Activity {
    private static final String DB_NAME = "ManchuDict.SQLite";

    private SQLiteDatabase database;
    private WordAdapter adapter;
    private TextView countText;
    private RotatedScriptView scriptView;
    private TextView romanText;
    private TextView chineseText;
    private TextView englishText;
    private TextView attributeText;
    private TextView examplesText;
    private final List<Word> words = new ArrayList<Word>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(0xfff4f1ea);
        root.setFocusable(true);
        root.setFocusableInTouchMode(true);
        root.setPadding(dp(10), dp(10), dp(10), dp(10));

        LinearLayout header = new LinearLayout(this);
        header.setGravity(Gravity.CENTER_VERTICAL);

        ImageView icon = new ImageView(this);
        icon.setImageResource(R.drawable.app_icon);
        LinearLayout.LayoutParams iconParams = new LinearLayout.LayoutParams(dp(42), dp(42));
        iconParams.setMargins(0, 0, dp(10), 0);
        header.addView(icon, iconParams);

        TextView title = label("SwiftManchu", 24, 0xff2d2417);
        title.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        header.addView(title, new LinearLayout.LayoutParams(
                0,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                1f));
        root.addView(header, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT));

        final EditText search = new EditText(this);
        search.setSingleLine(true);
        search.setHint("Search Manchu, Chinese, English");
        search.setTextSize(16);
        search.setPadding(dp(12), 0, dp(12), 0);
        search.setBackground(rounded(0xffffffff, 1, 0xffd7cabb, 8));
        root.addView(search, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT));

        LinearLayout listPanel = panel();
        countText = label("", 13, 0xff5f6368);
        countText.setPadding(dp(12), dp(8), dp(12), dp(4));
        listPanel.addView(countText, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT));

        ListView listView = new ListView(this);
        listView.setDividerHeight(1);
        listView.setCacheColorHint(0x00000000);
        listView.setBackgroundColor(0xffffffff);
        adapter = new WordAdapter();
        listView.setAdapter(adapter);
        listPanel.addView(listView, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f));
        root.addView(listPanel, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f));

        View separator = new View(this);
        separator.setBackgroundColor(0xff9f7f43);
        LinearLayout.LayoutParams separatorParams = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(3));
        separatorParams.setMargins(0, dp(8), 0, dp(8));
        root.addView(separator, separatorParams);

        LinearLayout detailPanel = panel();
        TextView detailLabel = label("Details", 14, 0xff7a5a22);
        detailLabel.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        detailLabel.setPadding(dp(12), dp(10), dp(12), 0);
        detailPanel.addView(detailLabel, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT));

        ScrollView detailScroll = new ScrollView(this);
        LinearLayout detailContent = new LinearLayout(this);
        detailContent.setOrientation(LinearLayout.VERTICAL);
        detailContent.setPadding(dp(12), dp(10), dp(12), dp(12));

        LinearLayout hero = new LinearLayout(this);
        hero.setOrientation(LinearLayout.HORIZONTAL);

        scriptView = new RotatedScriptView();
        scriptView.setBackground(rounded(0xfffbf7ed, 1, 0xffd7cabb, 8));
        hero.addView(scriptView, new LinearLayout.LayoutParams(dp(124), dp(198)));

        LinearLayout facts = new LinearLayout(this);
        facts.setOrientation(LinearLayout.VERTICAL);
        facts.setPadding(dp(14), 0, 0, 0);
        romanText = label("Loading dictionary...", 24, 0xff202124);
        romanText.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        chineseText = label("", 21, 0xff202124);
        englishText = label("", 18, 0xff3c4043);
        attributeText = label("", 16, 0xff7a5a22);
        facts.addView(romanText);
        facts.addView(chineseText);
        facts.addView(englishText);
        facts.addView(attributeText);
        hero.addView(facts, new LinearLayout.LayoutParams(
                0,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                1f));
        detailContent.addView(hero);

        examplesText = label("", 18, 0xff2f3437);
        examplesText.setTextIsSelectable(true);
        examplesText.setPadding(0, dp(14), 0, 0);
        examplesText.setLineSpacing(0, 1.08f);
        detailContent.addView(examplesText);
        detailScroll.addView(detailContent);
        detailPanel.addView(detailScroll, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f));
        root.addView(detailPanel, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1.15f));

        setContentView(root);
        getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_HIDDEN);
        root.requestFocus();

        try {
            database = openDictionary();
            refresh("");
        } catch (IOException error) {
            showMessage("Could not open dictionary", error.getMessage());
        }

        search.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) { }
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) { }
            @Override public void afterTextChanged(Editable s) {
                refresh(s.toString());
            }
        });

        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                showWord(words.get(position));
            }
        });
    }

    @Override
    protected void onDestroy() {
        if (database != null) {
            database.close();
        }
        super.onDestroy();
    }

    private SQLiteDatabase openDictionary() throws IOException {
        File file = getDatabasePath(DB_NAME);
        if (!file.exists()) {
            File parent = file.getParentFile();
            if (parent != null && !parent.exists() && !parent.mkdirs()) {
                throw new IOException("Could not create " + parent);
            }
            InputStream in = getAssets().open(DB_NAME);
            try {
                FileOutputStream out = new FileOutputStream(file);
                try {
                    byte[] buffer = new byte[8192];
                    int read;
                    while ((read = in.read(buffer)) != -1) {
                        out.write(buffer, 0, read);
                    }
                } finally {
                    out.close();
                }
            } finally {
                in.close();
            }
        }
        return SQLiteDatabase.openDatabase(file.getPath(), null, SQLiteDatabase.OPEN_READONLY);
    }

    private void refresh(String query) {
        if (database == null) {
            return;
        }

        words.clear();
        String trimmed = query.trim();
        Cursor cursor;
        if (trimmed.length() == 0) {
            cursor = database.rawQuery(
                    "select id, mnc, chn, eng, coalesce(attribute, '') from Word order by id limit 120",
                    null);
        } else {
            String like = "%" + trimmed + "%";
            String prefix = trimmed + "%";
            cursor = database.rawQuery(
                    "select id, mnc, chn, eng, coalesce(attribute, '') from Word " +
                            "where mnc like ? or chn like ? or eng like ? " +
                            "order by case " +
                            "when lower(mnc) = lower(?) then 0 " +
                            "when chn = ? then 1 " +
                            "when lower(eng) = lower(?) then 2 " +
                            "when mnc like ? then 3 " +
                            "when chn like ? then 4 " +
                            "else 5 end, id limit 120",
                    new String[] { like, like, like, trimmed, trimmed, trimmed, prefix, prefix });
        }

        try {
            while (cursor.moveToNext()) {
                words.add(new Word(
                        cursor.getInt(0),
                        cursor.getString(1),
                        cursor.getString(2),
                        cursor.getString(3),
                        cursor.getString(4)));
            }
        } finally {
            cursor.close();
        }

        adapter.notifyDataSetChanged();
        countText.setText(words.size() + " results");
        if (words.isEmpty()) {
            showMessage("No matches.", "");
        } else {
            showWord(words.get(0));
        }
    }

    private void showWord(Word word) {
        scriptView.setScript(ManchuScript.fromRomanized(word.manchu));
        romanText.setText(word.manchu);
        chineseText.setText(word.chinese);
        englishText.setText(word.english);
        attributeText.setText(word.attribute);
        attributeText.setVisibility(word.attribute.length() > 0 ? View.VISIBLE : View.GONE);

        StringBuilder text = new StringBuilder();
        Cursor cursor = database.rawQuery(
                "select sentmnc, sentchn, senteng from Sentence where wordid = ? order by sentid",
                new String[] { String.valueOf(word.id) });
        try {
            if (cursor.getCount() > 0) {
                text.append("Examples\n");
                while (cursor.moveToNext()) {
                    text.append("\n").append(cursor.getString(0)).append('\n');
                    text.append(cursor.getString(1)).append('\n');
                    text.append(cursor.getString(2)).append('\n');
                }
            }
        } finally {
            cursor.close();
        }
        examplesText.setText(text.toString());
    }

    private void showMessage(String title, String body) {
        scriptView.setScript("");
        romanText.setText(title);
        chineseText.setText(body);
        englishText.setText("");
        attributeText.setText("");
        examplesText.setText("");
    }

    private TextView label(String text, int sp, int color) {
        TextView view = new TextView(this);
        view.setText(text);
        view.setTextSize(sp);
        view.setTextColor(color);
        return view;
    }

    private LinearLayout panel() {
        LinearLayout panel = new LinearLayout(this);
        panel.setOrientation(LinearLayout.VERTICAL);
        panel.setBackground(rounded(0xffffffff, 1, 0xffddd3c4, 8));
        return panel;
    }

    private GradientDrawable rounded(int color, int strokeDp, int strokeColor, int radiusDp) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(color);
        drawable.setCornerRadius(dp(radiusDp));
        drawable.setStroke(dp(strokeDp), strokeColor);
        return drawable;
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
    }

    private final class RotatedScriptView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.SUBPIXEL_TEXT_FLAG);
        private final List<String> lines = new ArrayList<String>();
        private String script = "";

        RotatedScriptView() {
            super(MainActivity.this);
            paint.setColor(0xff2d2417);
            paint.setTextAlign(Paint.Align.CENTER);
            paint.setTextLocale(Locale.forLanguageTag("mn-Mong"));
        }

        void setScript(String script) {
            this.script = script == null ? "" : script.trim();
            invalidate();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            if (script.length() == 0) {
                return;
            }
            float padding = dp(12);
            float maxLineLength = Math.max(1, getHeight() - padding * 2);
            float maxColumnsWidth = Math.max(1, getWidth() - padding * 2);
            float textSize = dp(42);
            float minTextSize = dp(22);
            float lineHeight;

            do {
                paint.setTextSize(textSize);
                wrapLines(maxLineLength);
                lineHeight = (paint.descent() - paint.ascent()) * 1.06f;
                if (widestLine() <= maxLineLength && lines.size() * lineHeight <= maxColumnsWidth) {
                    break;
                }
                textSize -= dp(2);
            } while (textSize >= minTextSize);

            paint.setTextSize(Math.max(textSize, minTextSize));
            wrapLines(maxLineLength);
            lineHeight = (paint.descent() - paint.ascent()) * 1.06f;
            // ponytail: rotated word columns preserve joins; replace with native vertical shaping if Android exposes it reliably.
            canvas.save();
            canvas.translate(getWidth() / 2f, getHeight() / 2f);
            canvas.rotate(90);
            Paint.FontMetrics metrics = paint.getFontMetrics();
            float totalHeight = (lines.size() - 1) * lineHeight;
            for (int i = 0; i < lines.size(); i++) {
                float lineCenter = totalHeight / 2f - i * lineHeight;
                float baseline = lineCenter - (metrics.ascent + metrics.descent) / 2f;
                canvas.drawText(lines.get(i), 0, baseline, paint);
            }
            canvas.restore();
        }

        private void wrapLines(float maxLineLength) {
            lines.clear();
            String[] words = script.split("\\s+");
            String current = "";
            for (String word : words) {
                if (word.length() == 0) {
                    continue;
                }
                String candidate = current.length() == 0 ? word : current + " " + word;
                if (current.length() > 0 && paint.measureText(candidate) > maxLineLength) {
                    lines.add(current);
                    current = word;
                } else {
                    current = candidate;
                }
            }
            if (current.length() > 0) {
                lines.add(current);
            }
        }

        private float widestLine() {
            float widest = 0;
            for (String line : lines) {
                widest = Math.max(widest, paint.measureText(line));
            }
            return widest;
        }
    }

    private final class WordAdapter extends BaseAdapter {
        @Override public int getCount() { return words.size(); }
        @Override public Object getItem(int position) { return words.get(position); }
        @Override public long getItemId(int position) { return words.get(position).id; }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            RowHolder holder;
            if (convertView == null) {
                LinearLayout row = new LinearLayout(MainActivity.this);
                row.setOrientation(LinearLayout.VERTICAL);
                row.setPadding(dp(12), dp(9), dp(12), dp(9));

                TextView head = label("", 18, 0xff202124);
                head.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
                TextView sub = label("", 14, 0xff5f6368);
                row.addView(head);
                row.addView(sub);

                holder = new RowHolder();
                holder.head = head;
                holder.sub = sub;
                row.setTag(holder);
                convertView = row;
            } else {
                holder = (RowHolder) convertView.getTag();
            }

            Word word = words.get(position);
            holder.head.setText(word.manchu + "  " + word.chinese);
            holder.sub.setText(word.english);
            return convertView;
        }
    }

    private static final class RowHolder {
        TextView head;
        TextView sub;
    }

    private static final class Word {
        final int id;
        final String manchu;
        final String chinese;
        final String english;
        final String attribute;

        Word(int id, String manchu, String chinese, String english, String attribute) {
            this.id = id;
            this.manchu = manchu == null ? "" : manchu;
            this.chinese = chinese == null ? "" : chinese;
            this.english = english == null ? "" : english;
            this.attribute = attribute == null ? "" : attribute;
        }
    }

    private static final class ManchuScript {
        static String fromRomanized(String romanized) {
            String lower = romanized.toLowerCase(Locale.ROOT);
            StringBuilder result = new StringBuilder();
            for (int i = 0; i < lower.length(); i++) {
                char current = lower.charAt(i);
                if (current == 'n' && i + 1 < lower.length() && lower.charAt(i + 1) == 'g') {
                    result.append('\u1829');
                    i++;
                } else if (current == 'k' || current == 'g' || current == 'h') {
                    result.append(velarOrUvular(current, nextLetter(lower, i + 1)));
                } else {
                    result.append(mapped(current));
                }
            }
            return result.toString();
        }

        private static char nextLetter(String text, int index) {
            for (int i = index; i < text.length(); i++) {
                char ch = text.charAt(i);
                if (Character.isLetter(ch)) {
                    return ch;
                }
            }
            return 0;
        }

        private static char velarOrUvular(char ch, char next) {
            boolean front = next == 'e' || next == 'i' || next == 'u';
            if (ch == 'k') {
                return front ? '\u183a' : '\u182c';
            }
            if (ch == 'g') {
                return '\u182d';
            }
            return front ? '\u183b' : '\u183e';
        }

        private static char mapped(char ch) {
            switch (ch) {
                case 'a': return '\u1820';
                case 'e': return '\u1821';
                case 'i': return '\u1873';
                case 'o': return '\u1823';
                case 'u': return '\u1824';
                case 'ū': return '\u1826';
                case 'n': return '\u1828';
                case 'b': return '\u182a';
                case 'p': return '\u182b';
                case 's': return '\u1830';
                case 'š': return '\u1831';
                case 't': return '\u1832';
                case 'd': return '\u1833';
                case 'l': return '\u182f';
                case 'm': return '\u182e';
                case 'c': return '\u1834';
                case 'j': return '\u1835';
                case 'y': return '\u1836';
                case 'r': return '\u1837';
                case 'w': return '\u1838';
                case 'f': return '\u1839';
                case 'z': return '\u183d';
                case 'ž': return '\u183f';
                default: return ch;
            }
        }
    }
}
