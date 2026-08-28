package com.example.secretagentpin;

import android.app.Activity;
import android.os.Bundle;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.widget.Button;
import android.widget.TextView;
import java.util.Random;

public class MainActivity extends Activity {
    private final StringBuilder code = new StringBuilder();
    private TextView dotsText, messageText;
    private final Random random = new Random();
    private final String[] successMessages = {"ACCESS GRANTED! 🎉", "Secret code accepted, Agent! 🕵️", "Mission unlocked! 🚀", "Welcome to HQ! ⭐", "Super code! You did it! 🏆"};
    private final String[] retryMessages = {"Hmm... try another secret code! 😄", "Almost! HQ says try again! 🔐", "Beep beep! New code, Agent! 🤖", "That was sneaky! Try once more! 🕵️"};

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState); setContentView(R.layout.activity_main);
        dotsText=findViewById(R.id.dotsText); messageText=findViewById(R.id.messageText);
        int[] ids={R.id.b0,R.id.b1,R.id.b2,R.id.b3,R.id.b4,R.id.b5,R.id.b6,R.id.b7,R.id.b8,R.id.b9};
        for(int id:ids){ Button b=findViewById(id); b.setOnClickListener(v->addDigit(((Button)v).getText().toString())); }
        findViewById(R.id.backspace).setOnClickListener(v->removeDigit());
        findViewById(R.id.enter).setOnClickListener(v->submitCode()); updateDots();
    }
    private void addDigit(String d){ if(code.length()<4){code.append(d);vibrate(30);updateDots();messageText.setText(code.length()==4?"Press ✓ to check the secret code":"Keep going, Agent!");}}
    private void removeDigit(){if(code.length()>0){code.deleteCharAt(code.length()-1);vibrate(20);updateDots();messageText.setText("Code corrected!");}}
    private void submitCode(){if(code.length()<4){messageText.setText("Enter 4 numbers first 😊");vibrate(50);return;} boolean ok=random.nextInt(100)<75;String[] s=ok?successMessages:retryMessages;messageText.setText(s[random.nextInt(s.length)]);vibrate(ok?120:70);code.setLength(0);updateDots();}
    private void updateDots(){StringBuilder d=new StringBuilder();for(int i=0;i<4;i++){d.append(i<code.length()?"●":"○");if(i<3)d.append("  ");}dotsText.setText(d.toString());}
    private void vibrate(long ms){Vibrator v=(Vibrator)getSystemService(VIBRATOR_SERVICE);if(v==null||!v.hasVibrator())return;if(android.os.Build.VERSION.SDK_INT>=26)v.vibrate(VibrationEffect.createOneShot(ms,VibrationEffect.DEFAULT_AMPLITUDE));else v.vibrate(ms);}
}
