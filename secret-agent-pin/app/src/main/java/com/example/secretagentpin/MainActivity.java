package com.example.secretagentpin;

import android.app.Activity;
import android.app.AlertDialog;
import android.media.AudioManager;
import android.media.ToneGenerator;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import java.util.Random;

public class MainActivity extends Activity {
    private final StringBuilder code = new StringBuilder();
    private TextView titleText, worldText, promptText, targetText, dotsText, messageText, starsText;
    private final Random random = new Random();
    private final Handler handler = new Handler(Looper.getMainLooper());
    private ToneGenerator tone;
    private boolean accepting = false, copyMode = false, soundOn = true;
    private String targetCode = "";
    private int stars = 0;
    private String world = "agent";

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState); setContentView(R.layout.activity_main);
        titleText=findViewById(R.id.titleText); worldText=findViewById(R.id.worldText); promptText=findViewById(R.id.promptText);
        targetText=findViewById(R.id.targetText); dotsText=findViewById(R.id.dotsText); messageText=findViewById(R.id.messageText); starsText=findViewById(R.id.starsText);
        tone = new ToneGenerator(AudioManager.STREAM_MUSIC, 55);
        int[] ids={R.id.b0,R.id.b1,R.id.b2,R.id.b3,R.id.b4,R.id.b5,R.id.b6,R.id.b7,R.id.b8,R.id.b9};
        for(int id:ids){ Button b=findViewById(id); b.setOnClickListener(v->addDigit(((Button)v).getText().toString())); }
        findViewById(R.id.backspace).setOnClickListener(v->removeDigit());
        findViewById(R.id.soundButton).setOnClickListener(v->{soundOn=!soundOn; ((Button)v).setText(soundOn?"🔊":"🔇"); messageText.setText(soundOn?"Sounds on! 🎵":"Sounds off");});
        findViewById(R.id.worldAgent).setOnClickListener(v->setWorld("agent"));
        findViewById(R.id.worldSpace).setOnClickListener(v->setWorld("space"));
        findViewById(R.id.worldCastle).setOnClickListener(v->setWorld("castle"));
        findViewById(R.id.modeFree).setOnClickListener(v->setMode(false));
        findViewById(R.id.modeCopy).setOnClickListener(v->setMode(true));
        findViewById(R.id.parentText).setOnLongClickListener(v->{showParentInfo(); return true;});
        setWorld("agent"); setMode(false); updateDots();
    }

    private void addDigit(String d){
        if(accepting||code.length()>=4)return;
        code.append(d); vibrate(25); playTone(d); updateDots();
        if(code.length()==4){ accepting=true; handler.postDelayed(this::evaluateCode,180); }
        else messageText.setText(copyMode?"Copy the code above 🧠":"Keep going!");
    }

    private void evaluateCode(){
        boolean success=!copyMode || code.toString().equals(targetCode);
        if(success){ stars++; starsText.setText("⭐ Missions: "+stars); successFeedback(); }
        else { messageText.setText("Almost! Try that code again 😊"); vibrate(70); if(soundOn)tone.startTone(ToneGenerator.TONE_PROP_NACK,120); }
        handler.postDelayed(()->{code.setLength(0); accepting=false; updateDots(); if(copyMode){if(success)newTarget(); else messageText.setText("Try: "+spaced(targetCode));} else messageText.setText("Ready — enter another code! 🔢");},700);
    }

    private void successFeedback(){
        if(soundOn)tone.startTone(ToneGenerator.TONE_PROP_ACK,180); vibrate(120);
        if(world.equals("space")) messageText.setText("ROCKET LAUNCHED! 🚀✨");
        else if(world.equals("castle")) messageText.setText("CASTLE UNLOCKED! 🏰✨");
        else messageText.setText("ACCESS GRANTED! 🕵️⭐");
    }

    private void setWorld(String w){ world=w; code.setLength(0); accepting=false; updateDots();
        if(w.equals("space")){titleText.setText("🚀 SPACE MISSION");worldText.setText("Mission: Launch Control");promptText.setText("Enter the launch code!");}
        else if(w.equals("castle")){titleText.setText("🏰 MAGIC CASTLE");worldText.setText("Mission: Unlock the Castle");promptText.setText("Enter the magic number code!");}
        else {titleText.setText("🕵️ SECRET AGENT HQ");worldText.setText("Mission: Secret Agent");promptText.setText("Enter your secret code, Agent!");}
        if(copyMode)newTarget(); else messageText.setText("Tap any 4 numbers");
    }

    private void setMode(boolean copy){ copyMode=copy; code.setLength(0); accepting=false; updateDots();
        if(copyMode){targetText.setVisibility(View.VISIBLE); newTarget();}
        else {targetText.setVisibility(View.GONE); targetText.setText(""); messageText.setText("Free Play — any 4 numbers work! ∞");}
    }

    private void newTarget(){ StringBuilder t=new StringBuilder(); for(int i=0;i<4;i++)t.append(random.nextInt(10)); targetCode=t.toString(); targetText.setText("COPY:  "+spaced(targetCode)); messageText.setText("Can you copy this code? 🧠"); }
    private String spaced(String s){return s.charAt(0)+"   "+s.charAt(1)+"   "+s.charAt(2)+"   "+s.charAt(3);}
    private void removeDigit(){if(accepting)return;if(code.length()>0){code.deleteCharAt(code.length()-1);vibrate(20);updateDots();}}
    private void updateDots(){StringBuilder d=new StringBuilder();for(int i=0;i<4;i++){d.append(i<code.length()?"●":"○");if(i<3)d.append("  ");}if(dotsText!=null)dotsText.setText(d.toString());}
    private void playTone(String digit){if(!soundOn||tone==null)return; int n=Integer.parseInt(digit); tone.startTone(ToneGenerator.TONE_DTMF_0+n,70);}
    private void vibrate(long ms){Vibrator v=(Vibrator)getSystemService(VIBRATOR_SERVICE);if(v==null||!v.hasVibrator())return;if(android.os.Build.VERSION.SDK_INT>=26)v.vibrate(VibrationEffect.createOneShot(ms,VibrationEffect.DEFAULT_AMPLITUDE));else v.vibrate(ms);}
    private void showParentInfo(){new AlertDialog.Builder(this).setTitle("Parent Zone 👨‍👩‍👧").setMessage("Parent Test Beta\n\n• Works offline\n• No account or login\n• No internet permission\n• No personal data collected by the app\n• No ads\n• Sound can be switched off\n\nPlease watch what your child enjoys and share feedback about ease of use, favourite mode, and anything confusing.").setPositiveButton("Got it",null).show();}
    @Override protected void onDestroy(){if(tone!=null)tone.release();super.onDestroy();}
}
