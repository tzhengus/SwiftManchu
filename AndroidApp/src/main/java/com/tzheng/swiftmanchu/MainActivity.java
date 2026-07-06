package com.tzheng.swiftmanchu;

import android.app.Activity;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.BaseAdapter;
import android.widget.EditText;
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
    private TextView detailText;
    private final List<Word> words = new ArrayList<Word>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(0xfffafafa);
        root.setPadding(dp(12), dp(10), dp(12), dp(10));

        TextView title = label("SwiftManchu", 22, 0xff202124);
        root.addView(title, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT));

        final EditText search = new EditText(this);
        search.setSingleLine(true);
        search.setHint("Search Manchu, Chinese, English");
        search.setTextSize(16);
        root.addView(search, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT));

        countText = label("", 13, 0xff5f6368);
        root.addView(countText, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT));

        ListView listView = new ListView(this);
        listView.setDividerHeight(1);
        adapter = new WordAdapter();
        listView.setAdapter(adapter);
        root.addView(listView, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f));

        ScrollView detailScroll = new ScrollView(this);
        detailText = label("Loading dictionary...", 16, 0xff202124);
        detailText.setTextIsSelectable(true);
        detailText.setPadding(0, dp(12), 0, 0);
        detailScroll.addView(detailText);
        root.addView(detailScroll, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f));

        setContentView(root);

        try {
            database = openDictionary();
            refresh("");
        } catch (IOException error) {
            detailText.setText("Could not open dictionary:\n" + error.getMessage());
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
            detailText.setText("No matches.");
        } else {
            showWord(words.get(0));
        }
    }

    private void showWord(Word word) {
        StringBuilder text = new StringBuilder();
        text.append(word.manchu).append('\n');
        text.append(ManchuScript.fromRomanized(word.manchu)).append('\n');
        text.append('\n').append(word.chinese).append('\n');
        text.append(word.english).append('\n');
        if (word.attribute.length() > 0) {
            text.append(word.attribute).append('\n');
        }

        Cursor cursor = database.rawQuery(
                "select sentmnc, sentchn, senteng from Sentence where wordid = ? order by sentid",
                new String[] { String.valueOf(word.id) });
        try {
            if (cursor.getCount() > 0) {
                text.append("\nExamples\n");
                while (cursor.moveToNext()) {
                    text.append("\n").append(cursor.getString(0)).append('\n');
                    text.append(cursor.getString(1)).append('\n');
                    text.append(cursor.getString(2)).append('\n');
                }
            }
        } finally {
            cursor.close();
        }
        detailText.setText(text.toString());
    }

    private TextView label(String text, int sp, int color) {
        TextView view = new TextView(this);
        view.setText(text);
        view.setTextSize(sp);
        view.setTextColor(color);
        return view;
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
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
                row.setPadding(0, dp(8), 0, dp(8));

                TextView head = label("", 18, 0xff202124);
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
