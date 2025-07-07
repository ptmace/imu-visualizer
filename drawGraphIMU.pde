import processing.serial.*;

Serial myPort;

final int WINDOW_SIZE = 20;
final int MAX_POINTS = 600;  // Số điểm hiển thị trên đồ thị

// Danh sách giá trị
ArrayList<Float> rawRollList = new ArrayList<Float>();
ArrayList<Float> smoothRollList = new ArrayList<Float>();

ArrayList<Float> rawPitchList = new ArrayList<Float>();
ArrayList<Float> smoothPitchList = new ArrayList<Float>();

ArrayList<Float> rawYawList = new ArrayList<Float>();
ArrayList<Float> smoothYawList = new ArrayList<Float>();

// Buffer trượt
float[] rollBuffer = new float[WINDOW_SIZE];
float[] pitchBuffer = new float[WINDOW_SIZE];
float[] yawBuffer = new float[WINDOW_SIZE];

int rollIndex = 0, pitchIndex = 0, yawIndex = 0;
int rollCount = 0, pitchCount = 0, yawCount = 0;

void setup() {
  size(1000, 750);
  println("Serial ports available:");
  println(Serial.list());
  myPort = new Serial(this, Serial.list()[0], 115200);
  myPort.bufferUntil('\n');
}

void draw() {
  background(255);
  
  // RED for all raw
  color rawColor = color(255, 100, 100);

  drawGraph("ROLL", rawRollList, smoothRollList, rawColor, color(255, 180, 0), 100, -180, 180);   // vàng
  drawGraph("PITCH", rawPitchList, smoothPitchList, rawColor, color(0, 0, 255), 300, -90, 90);    // xanh dương
  drawGraph("YAW", rawYawList, smoothYawList, rawColor, color(0, 180, 0), 500, -90, 90);          // xanh lá


}

void drawGraph(String label, ArrayList<Float> raw, ArrayList<Float> filtered, 
               color rawColor, color smoothColor, int yOffset,
               float minVal, float maxVal) {
  drawAxes(yOffset, label, minVal, maxVal);

  // Vẽ tín hiệu raw
  stroke(rawColor);
  noFill();
  beginShape();
  for (int i = 0; i < raw.size(); i++) {
    float y = map(constrain(raw.get(i), minVal, maxVal), minVal, maxVal, yOffset + 60, yOffset - 60);
    vertex(60 + i, y);
  }
  endShape();

  // Vẽ tín hiệu đã lọc
  stroke(smoothColor);
  noFill();
  beginShape();
  for (int i = 0; i < filtered.size(); i++) {
    float y = map(constrain(filtered.get(i), minVal, maxVal), minVal, maxVal, yOffset + 60, yOffset - 60);
    vertex(60 + i, y);
  }
  endShape();
}


void drawAxes(int yOffset, String label, float minVal, float maxVal) {
  stroke(0);
  fill(0);
  textSize(12);

  // Xác định khoảng chia trục Y
  int step = (int)(maxVal - minVal) <= 180 ? 30 : 60;

  // Trục Y
  for (int r = int(minVal); r <= int(maxVal); r += step) {
    float y = map(r, minVal, maxVal, yOffset + 60, yOffset - 60);
    stroke(220);
    line(60, y, 60 + MAX_POINTS, y);
    stroke(0);
    text(nf(r, 0, 0), 25, y + 5);
  }

  // Trục X
  for (int t = 0; t <= MAX_POINTS; t += 100) {
    float x = 60 + t;
    stroke(220);
    line(x, yOffset + 60, x, yOffset - 60);
    stroke(0);
    text(str(t), x - 10, yOffset + 75);
  }

  // Viền
  stroke(0);
  noFill();
  rect(60, yOffset - 60, MAX_POINTS, 120);

  text(label + " (Raw: Đỏ nhạt, Filtered: Cam/Xanh dương/Xanh lá)", width/2 - 80, yOffset - 75);
}


void serialEvent(Serial myPort) {
  String input = myPort.readStringUntil('\n');
  if (input != null) {
    input = trim(input);
    String[] parts = split(input, ",");
    if (parts.length == 3) {
      try {
        float roll = Float.parseFloat(trim(split(parts[0], ":")[1]));
        float pitch = Float.parseFloat(trim(split(parts[1], ":")[1]));
        float yaw = Float.parseFloat(trim(split(parts[2], ":")[1]));

        float rollFiltered = updateAverage(roll, rollBuffer, "roll");
        float pitchFiltered = updateAverage(pitch, pitchBuffer, "pitch");
        float yawFiltered = updateAverage(yaw, yawBuffer, "yaw");

        updateList(rawRollList, roll);
        updateList(smoothRollList, rollFiltered);

        updateList(rawPitchList, pitch);
        updateList(smoothPitchList, pitchFiltered);

        updateList(rawYawList, yaw);
        updateList(smoothYawList, yawFiltered);

        println("ROLL: " + nf(roll, 1, 2) + " => " + nf(rollFiltered, 1, 2));
      } catch (Exception e) {
        println("⚠️ Lỗi xử lý: " + e);
      }
    }
  }
}

float updateAverage(float val, float[] buffer, String axis) {
  int index = 0, count = 0;

  if (axis.equals("roll")) {
    index = rollIndex;
    count = rollCount;
  } else if (axis.equals("pitch")) {
    index = pitchIndex;
    count = pitchCount;
  } else if (axis.equals("yaw")) {
    index = yawIndex;
    count = yawCount;
  }

  buffer[index] = val;
  index = (index + 1) % WINDOW_SIZE;
  if (count < WINDOW_SIZE) count++;

  float sum = 0;
  for (int i = 0; i < count; i++) sum += buffer[i];
  float avg = sum / count;

  if (axis.equals("roll")) {
    rollIndex = index;
    rollCount = count;
  } else if (axis.equals("pitch")) {
    pitchIndex = index;
    pitchCount = count;
  } else if (axis.equals("yaw")) {
    yawIndex = index;
    yawCount = count;
  }

  return avg;
}

void updateList(ArrayList<Float> list, float val) {
  list.add(val);
  if (list.size() > MAX_POINTS) list.remove(0);
}
