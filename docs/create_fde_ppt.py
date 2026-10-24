from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.util import Inches, Pt
import copy

prs = Presentation()
prs.slide_width  = Inches(13.33)
prs.slide_height = Inches(7.5)

# ── Colour palette ──────────────────────────────────────────────
BG        = RGBColor(0x05, 0x08, 0x14)   # near-black
SURFACE   = RGBColor(0x0D, 0x13, 0x26)
CARD      = RGBColor(0x11, 0x18, 0x27)
ACCENT1   = RGBColor(0x6C, 0x63, 0xFF)   # violet
ACCENT2   = RGBColor(0x00, 0xD4, 0xFF)   # cyan
ACCENT3   = RGBColor(0xFF, 0x6B, 0x9D)   # pink
ACCENT4   = RGBColor(0xFF, 0xD1, 0x66)   # yellow
ACCENT5   = RGBColor(0x06, 0xD6, 0xA0)   # green
WHITE     = RGBColor(0xFF, 0xFF, 0xFF)
MUTED     = RGBColor(0x88, 0x92, 0xA4)
BORDER    = RGBColor(0x1E, 0x2D, 0x4A)

# ── Blank layout ────────────────────────────────────────────────
BLANK_LAYOUT = prs.slide_layouts[6]

def add_slide():
    return prs.slides.add_slide(BLANK_LAYOUT)

def fill_bg(slide, color=BG):
    bg = slide.background
    fill = bg.fill
    fill.solid()
    fill.fore_color.rgb = color

def add_rect(slide, l, t, w, h, color, alpha=None):
    shape = slide.shapes.add_shape(1, Inches(l), Inches(t), Inches(w), Inches(h))
    shape.line.fill.background()
    shape.fill.solid()
    shape.fill.fore_color.rgb = color
    return shape

def add_text(slide, text, l, t, w, h,
             size=18, bold=False, color=WHITE, align=PP_ALIGN.LEFT,
             italic=False, wrap=True):
    txBox = slide.shapes.add_textbox(Inches(l), Inches(t), Inches(w), Inches(h))
    tf = txBox.text_frame
    tf.word_wrap = wrap
    p = tf.paragraphs[0]
    p.alignment = align
    run = p.add_run()
    run.text = text
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.italic = italic
    run.font.color.rgb = color
    return txBox

def add_para(tf, text, size=14, bold=False, color=WHITE,
             align=PP_ALIGN.LEFT, italic=False, space_before=Pt(4)):
    from pptx.util import Pt as Pt2
    p = tf.add_paragraph()
    p.alignment = align
    p.space_before = space_before
    run = p.add_run()
    run.text = text
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.italic = italic
    run.font.color.rgb = color
    return p

def add_card(slide, l, t, w, h, icon, title, body, accent):
    # card bg
    card = slide.shapes.add_shape(1, Inches(l), Inches(t), Inches(w), Inches(h))
    card.fill.solid(); card.fill.fore_color.rgb = CARD
    card.line.color.rgb = BORDER; card.line.width = Pt(0.5)

    # top accent bar
    bar = slide.shapes.add_shape(1, Inches(l), Inches(t), Inches(w), Inches(0.06))
    bar.fill.solid(); bar.fill.fore_color.rgb = accent
    bar.line.fill.background()

    # icon
    add_text(slide, icon, l+0.12, t+0.1, w-0.2, 0.45, size=22, color=WHITE)
    # title
    add_text(slide, title, l+0.12, t+0.52, w-0.2, 0.35, size=12, bold=True, color=WHITE)
    # body
    add_text(slide, body, l+0.12, t+0.9, w-0.2, h-1.05, size=9, color=MUTED, wrap=True)

def add_pill(slide, l, t, text, color):
    w = len(text)*0.095 + 0.3
    box = slide.shapes.add_shape(9, Inches(l), Inches(t), Inches(w), Inches(0.32))
    box.fill.solid(); box.fill.fore_color.rgb = CARD
    box.line.color.rgb = color; box.line.width = Pt(0.8)
    add_text(slide, text, l+0.08, t+0.02, w-0.12, 0.3, size=9, bold=True, color=color, align=PP_ALIGN.CENTER)
    return w

def slide_footer(slide, current, total):
    # progress bar bg
    pbg = slide.shapes.add_shape(1, Inches(0), Inches(7.35), Inches(13.33), Inches(0.06))
    pbg.fill.solid(); pbg.fill.fore_color.rgb = BORDER; pbg.line.fill.background()
    # progress bar fill
    pw = 13.33 * (current / total)
    pf = slide.shapes.add_shape(1, Inches(0), Inches(7.35), Inches(pw), Inches(0.06))
    pf.fill.solid(); pf.fill.fore_color.rgb = ACCENT2; pf.line.fill.background()
    # slide number
    add_text(slide, f"{current:02d} / {total:02d}", 12.4, 7.1, 0.8, 0.3,
             size=9, color=MUTED, align=PP_ALIGN.RIGHT)
    # logo
    add_text(slide, "BBHealthApp · FDE", 0.2, 7.1, 3, 0.3, size=9, color=ACCENT2)

TOTAL = 10

# ═══════════════════════════════════════════════
# SLIDE 1 – TITLE
# ═══════════════════════════════════════════════
sl = add_slide(); fill_bg(sl)

# gradient-ish circles (blobs)
c1 = sl.shapes.add_shape(9, Inches(-1), Inches(-1), Inches(6), Inches(6))
c1.fill.solid(); c1.fill.fore_color.rgb = RGBColor(0x12,0x0E,0x3A); c1.line.fill.background()
c2 = sl.shapes.add_shape(9, Inches(9), Inches(3), Inches(6), Inches(6))
c2.fill.solid(); c2.fill.fore_color.rgb = RGBColor(0x00,0x22,0x30); c2.line.fill.background()

# TAG
tag = sl.shapes.add_shape(9, Inches(5.2), Inches(1.0), Inches(2.9), Inches(0.38))
tag.fill.solid(); tag.fill.fore_color.rgb = RGBColor(0x16,0x12,0x44); tag.line.fill.background()
add_text(sl, "BBHealthApp Program", 5.25, 1.04, 2.8, 0.3, size=9, bold=True, color=ACCENT1, align=PP_ALIGN.CENTER)

# Main title
add_text(sl, "FDE", 2.5, 1.55, 8.3, 1.2, size=80, bold=True, color=ACCENT1, align=PP_ALIGN.CENTER)
add_text(sl, "Full-stack Development Experience", 1.5, 2.7, 10.3, 0.8, size=28, bold=True, color=WHITE, align=PP_ALIGN.CENTER)
add_text(sl, "A structured learning program bridging the gap between classrooms and\nreal-world cloud-native development — for freshers & experienced engineers.",
         2.0, 3.55, 9.33, 0.8, size=14, color=MUTED, align=PP_ALIGN.CENTER)

# Stat boxes
stats = [("4","Microservices",ACCENT1),("12","Tech Skills",ACCENT2),("8","Week Program",ACCENT5),("100%","Hands-on",ACCENT4)]
for i,(num,lbl,col) in enumerate(stats):
    x = 2.3 + i*2.2
    box = sl.shapes.add_shape(1, Inches(x), Inches(4.7), Inches(1.8), Inches(1.2))
    box.fill.solid(); box.fill.fore_color.rgb = CARD
    box.line.color.rgb = BORDER; box.line.width = Pt(0.5)
    add_text(sl, num, x, 4.72, 1.8, 0.55, size=26, bold=True, color=col, align=PP_ALIGN.CENTER)
    add_text(sl, lbl, x, 5.28, 1.8, 0.35, size=10, color=MUTED, align=PP_ALIGN.CENTER)

slide_footer(sl, 1, TOTAL)

# ═══════════════════════════════════════════════
# SLIDE 2 – WHAT IS FDE
# ═══════════════════════════════════════════════
sl = add_slide(); fill_bg(sl)
c1 = sl.shapes.add_shape(9, Inches(9), Inches(-1), Inches(6), Inches(6))
c1.fill.solid(); c1.fill.fore_color.rgb = RGBColor(0x00,0x22,0x30); c1.line.fill.background()

tag = sl.shapes.add_shape(9, Inches(5.2), Inches(0.25), Inches(2.9), Inches(0.35))
tag.fill.solid(); tag.fill.fore_color.rgb = RGBColor(0x00,0x22,0x28); tag.line.fill.background()
add_text(sl, "What is FDE?", 5.25, 0.27, 2.8, 0.3, size=9, bold=True, color=ACCENT2, align=PP_ALIGN.CENTER)

add_text(sl, "Full-stack Development  Experience", 1.0, 0.65, 11.3, 0.7, size=26, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

# Left column – description
left_box = sl.shapes.add_textbox(Inches(0.5), Inches(1.55), Inches(5.8), Inches(5.5))
tf = left_box.text_frame; tf.word_wrap = True
add_para(tf, "FDE is a hands-on, project-based training program built around the real-world BBHealthApp — a COVID-19 Health Management System.", 12, color=MUTED)
add_para(tf, "", 6)
add_para(tf, "\"FDE turns classroom theory into real cloud-native product engineering.\"", 11, italic=True, color=ACCENT2)
add_para(tf, "", 6)
add_para(tf, "Unlike traditional courses, FDE uses a live, production-grade codebase covering frontend, backend, databases, DevOps, and cloud — all in one.", 12, color=MUTED)

# Right column – checklist
checks = [
    ("🎯","Goal-oriented","Learn by building and fixing real features in BBHealthApp"),
    ("🏗️","Architecture-first","Understand microservices before writing a single line of code"),
    ("☁️","Cloud-native","Deploy on AWS EKS with Kubernetes, Helm & CI/CD pipelines"),
    ("🔐","Security-aware","JWT, BCrypt, RBAC, CORS — baked in from day one"),
    ("🤝","Team-based","Git workflows, PR reviews, Jenkins pipelines like a real team"),
    ("📊","Measurable outcomes","Working deployments, documented PRs, and a portfolio"),
]
for i,(ico,ttl,desc) in enumerate(checks):
    y = 1.55 + i*0.87
    add_text(sl, ico, 6.7, y, 0.4, 0.5, size=16, color=WHITE)
    add_text(sl, ttl, 7.15, y, 5.5, 0.28, size=11, bold=True, color=WHITE)
    add_text(sl, desc, 7.15, y+0.3, 5.5, 0.5, size=9, color=MUTED, wrap=True)

slide_footer(sl, 2, TOTAL)

# ═══════════════════════════════════════════════
# SLIDE 3 – WHAT FDE DOES
# ═══════════════════════════════════════════════
sl = add_slide(); fill_bg(sl)
c1 = sl.shapes.add_shape(9, Inches(-1), Inches(4), Inches(5), Inches(5))
c1.fill.solid(); c1.fill.fore_color.rgb = RGBColor(0x00,0x25,0x20); c1.line.fill.background()

tag = sl.shapes.add_shape(9, Inches(5.2), Inches(0.2), Inches(2.9), Inches(0.35))
tag.fill.solid(); tag.fill.fore_color.rgb = RGBColor(0x00,0x25,0x20); tag.line.fill.background()
add_text(sl, "Core Functions", 5.25, 0.22, 2.8, 0.3, size=9, bold=True, color=ACCENT5, align=PP_ALIGN.CENTER)

add_text(sl, "What does FDE  do?", 1, 0.6, 11.33, 0.65, size=26, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

cards_data = [
    (ACCENT1,"🧩","Breaks Down Real Systems","Participants dissect BBHealthApp's 4 microservices — Master, Register, Document & Frontend — understanding how large systems communicate."),
    (ACCENT2,"🛠️","Teaches by Doing","Every concept — JWT auth to Kubernetes rolling updates — is applied directly inside a running project, not toy examples."),
    (ACCENT3,"🚀","Bridges Dev → Prod","Learn the full journey: Docker Compose → Jenkins CI/CD → AWS ECR → EKS cluster → ALB Ingress with SSL."),
    (ACCENT4,"🐛","Trains Debugging Skills","Real ERROR_LOG.md with documented issues: null token bugs, port conflicts, CORS errors — systematic root-cause analysis."),
    (ACCENT5,"📋","Builds Engineering Habits","Git commits, PR reviews, ARCHITECTURE.md, incident logging — industry-grade habits from day one."),
]
positions = [(0.35,1.45),(2.9,1.45),(5.45,1.45),(7.97,1.45),(10.5,1.45)]
for (x,y),(acc,ico,ttl,body) in zip(positions, cards_data):
    add_card(sl, x, y, 2.3, 5.7, ico, ttl, body, acc)

slide_footer(sl, 3, TOTAL)

# ═══════════════════════════════════════════════
# SLIDE 4 – TECH STACK
# ═══════════════════════════════════════════════
sl = add_slide(); fill_bg(sl)
c1 = sl.shapes.add_shape(9, Inches(8), Inches(-1), Inches(6), Inches(6))
c1.fill.solid(); c1.fill.fore_color.rgb = RGBColor(0x0C,0x10,0x35); c1.line.fill.background()

tag = sl.shapes.add_shape(9, Inches(5.1), Inches(0.2), Inches(3.1), Inches(0.35))
tag.fill.solid(); tag.fill.fore_color.rgb = RGBColor(0x0C,0x10,0x35); tag.line.fill.background()
add_text(sl, "Technology Stack", 5.15, 0.22, 3.0, 0.3, size=9, bold=True, color=ACCENT1, align=PP_ALIGN.CENTER)
add_text(sl, "Technologies Covered in FDE", 1, 0.6, 11.33, 0.6, size=26, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

sections = [
    ("FRONTEND", ACCENT2, ["⚛️ React.js 18","🎨 Material-UI","🔄 RxJS","🌐 Apache HTTPD","🔗 Axios"]),
    ("BACKEND", ACCENT1, ["☕ Spring Boot 2.3","🔐 Spring Security","🔑 JWT / BCrypt","🗄️ H2 / MySQL","📦 Maven"]),
    ("INFRASTRUCTURE & DEVOPS", ACCENT5, ["🐳 Docker","☸️ Kubernetes EKS","⛵ Helm","🏗️ Jenkins CI/CD","📦 AWS ECR","☁️ AWS ALB","🌱 Terraform"]),
]

y_start = 1.45
for i,(sec,col,pills) in enumerate(sections):
    y = y_start + i*1.8
    # section label
    lbl = sl.shapes.add_shape(1, Inches(0.4), Inches(y), Inches(1.6), Inches(0.28))
    lbl.fill.solid(); lbl.fill.fore_color.rgb = RGBColor(0x11,0x18,0x27); lbl.line.fill.background()
    add_text(sl, sec, 0.45, y+0.02, 1.5, 0.25, size=8, bold=True, color=col)

    # separator line
    line_s = sl.shapes.add_shape(1, Inches(0.4), Inches(y+0.32), Inches(12.53), Inches(0.02))
    line_s.fill.solid(); line_s.fill.fore_color.rgb = BORDER; line_s.line.fill.background()

    # pills
    x_cur = 0.4
    for pill_text in pills:
        pw = add_pill(sl, x_cur, y+0.48, pill_text, col)
        x_cur += pw + 0.2

slide_footer(sl, 4, TOTAL)

# ═══════════════════════════════════════════════
# SLIDE 5 – ARCHITECTURE
# ═══════════════════════════════════════════════
sl = add_slide(); fill_bg(sl)
c1 = sl.shapes.add_shape(9, Inches(-1), Inches(4), Inches(5), Inches(5))
c1.fill.solid(); c1.fill.fore_color.rgb = RGBColor(0x28,0x08,0x20); c1.line.fill.background()

tag = sl.shapes.add_shape(9, Inches(5.1), Inches(0.2), Inches(3.1), Inches(0.35))
tag.fill.solid(); tag.fill.fore_color.rgb = RGBColor(0x28,0x08,0x20); tag.line.fill.background()
add_text(sl, "System Architecture", 5.15, 0.22, 3.0, 0.3, size=9, bold=True, color=ACCENT3, align=PP_ALIGN.CENTER)
add_text(sl, "BBHealthApp Architecture", 1, 0.62, 11.33, 0.6, size=26, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

def arch_box(slide, l, t, w, h, icon, name, sub, col):
    box = slide.shapes.add_shape(1, Inches(l), Inches(t), Inches(w), Inches(h))
    box.fill.solid(); box.fill.fore_color.rgb = CARD
    box.line.color.rgb = col; box.line.width = Pt(0.8)
    add_text(slide, icon, l+0.08, t+0.08, w-0.15, 0.42, size=20, color=WHITE, align=PP_ALIGN.CENTER)
    add_text(slide, name, l+0.05, t+0.52, w-0.1, 0.3, size=11, bold=True, color=col, align=PP_ALIGN.CENTER)
    add_text(slide, sub,  l+0.05, t+0.84, w-0.1, 0.3, size=8,  color=MUTED, align=PP_ALIGN.CENTER)

def arrow(slide, l, t):
    a = slide.shapes.add_shape(1, Inches(l), Inches(t+0.45), Inches(0.4), Inches(0.08))
    a.fill.solid(); a.fill.fore_color.rgb = MUTED; a.line.fill.background()

arch_box(sl, 0.3,  1.5, 1.8, 1.3, "🌐","AWS ALB","SSL + Path Routing", ACCENT2)
arrow(sl, 2.15, 1.5)
arch_box(sl, 2.6,  1.5, 1.8, 1.3, "⚛️","Frontend","React + HTTPD · :80",  ACCENT1)
arrow(sl, 4.45, 1.5)

# Three backend boxes
arch_box(sl, 4.9,  1.2, 2.5, 1.15, "🔐","Master Service","Auth · JWT · RBAC · :8080",ACCENT3)
arch_box(sl, 4.9,  2.45,2.5, 1.15, "📝","Register Service","User Registration · :8082",ACCENT5)
arch_box(sl, 4.9,  3.7, 2.5, 1.15, "📄","Document Service","File Storage · :8083",    ACCENT4)

arrow(sl, 7.45, 2.0)

# Database + ECR
arch_box(sl, 7.9, 1.5, 2.0, 1.15, "🗄️","H2 / MySQL","Database", ACCENT1)
arch_box(sl, 10.0,1.5, 2.0, 1.15, "📦","AWS ECR","Image Registry", ACCENT2)

# Kubernetes wrapper label
add_text(sl, "☸️  AWS EKS — Kubernetes Orchestration   |   ⛵ Helm Deployments   |   🏗️ Jenkins CI/CD",
         0.3, 5.1, 12.7, 0.38, size=10, color=MUTED, align=PP_ALIGN.CENTER)

slide_footer(sl, 5, TOTAL)

# ═══════════════════════════════════════════════
# SLIDE 6 – USER ROLES
# ═══════════════════════════════════════════════
sl = add_slide(); fill_bg(sl)
c1 = sl.shapes.add_shape(9, Inches(9), Inches(-1), Inches(6), Inches(6))
c1.fill.solid(); c1.fill.fore_color.rgb = RGBColor(0x28,0x20,0x00); c1.line.fill.background()

tag = sl.shapes.add_shape(9, Inches(5.1), Inches(0.2), Inches(3.1), Inches(0.35))
tag.fill.solid(); tag.fill.fore_color.rgb = RGBColor(0x28,0x20,0x00); tag.line.fill.background()
add_text(sl, "Real-World Context", 5.15, 0.22, 3.0, 0.3, size=9, bold=True, color=ACCENT4, align=PP_ALIGN.CENTER)
add_text(sl, "User Roles in BBHealthApp", 1, 0.62, 11.33, 0.6, size=26, bold=True, color=WHITE, align=PP_ALIGN.CENTER)
add_text(sl, "FDE participants implement and understand features for 4 distinct user roles — each with different permissions, workflows, and dashboards.",
         1.5, 1.22, 10.33, 0.45, size=12, color=MUTED, align=PP_ALIGN.CENTER)

roles = [
    ("🏥","Patient (USER)",
     "• Request COVID tests\n• Book consultations\n• Upload medical documents\n• View test results & reports",
     ACCENT2),
    ("👨‍⚕️","Doctor",
     "• Review pending consultations\n• View patient test results\n• Provide medical consultation\n• Upload medical documents",
     ACCENT5),
    ("🧪","Tester",
     "• Manage test requests queue\n• Perform COVID tests\n• Update results (positive/negative)\n• Quarantine decisions",
     ACCENT3),
    ("🏛️","Government Authority",
     "• Approve user registrations\n• View analytics dashboard\n• Manage system thresholds\n• Oversee all operations",
     ACCENT4),
]

for i,(ico,title,desc,col) in enumerate(roles):
    x = 0.4 + i * 3.15
    box = sl.shapes.add_shape(1, Inches(x), Inches(1.85), Inches(2.9), Inches(4.8))
    box.fill.solid(); box.fill.fore_color.rgb = CARD
    box.line.color.rgb = col; box.line.width = Pt(0.6)

    bar = sl.shapes.add_shape(1, Inches(x), Inches(1.85), Inches(2.9), Inches(0.06))
    bar.fill.solid(); bar.fill.fore_color.rgb = col; bar.line.fill.background()

    add_text(sl, ico, x+0.1, 2.0, 2.7, 0.5, size=26, color=WHITE)
    add_text(sl, title, x+0.15, 2.6, 2.6, 0.38, size=13, bold=True, color=col)
    add_text(sl, desc, x+0.15, 3.08, 2.6, 3.3, size=10, color=MUTED, wrap=True)

add_text(sl, "Role-based access controlled via  Spring Security + JWT scopes",
         1.5, 6.85, 10.33, 0.38, size=9, color=MUTED, align=PP_ALIGN.CENTER)

slide_footer(sl, 6, TOTAL)

# ═══════════════════════════════════════════════
# SLIDE 7 – HOW FRESHERS PREPARE
# ═══════════════════════════════════════════════
sl = add_slide(); fill_bg(sl)
c1 = sl.shapes.add_shape(9, Inches(-1), Inches(4), Inches(5), Inches(5))
c1.fill.solid(); c1.fill.fore_color.rgb = RGBColor(0x0C,0x10,0x35); c1.line.fill.background()

tag = sl.shapes.add_shape(9, Inches(5.1), Inches(0.18), Inches(3.1), Inches(0.35))
tag.fill.solid(); tag.fill.fore_color.rgb = RGBColor(0x0C,0x10,0x35); tag.line.fill.background()
add_text(sl, "For Freshers", 5.15, 0.2, 3.0, 0.3, size=9, bold=True, color=ACCENT1, align=PP_ALIGN.CENTER)
add_text(sl, "How to Prepare as a Fresher", 1, 0.6, 11.33, 0.6, size=26, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

steps = [
    ("01",ACCENT1,"🌐","Master Web Basics","HTML, CSS, JavaScript fundamentals. Understand HTTP, REST APIs, and JSON — the language of the web."),
    ("02",ACCENT2,"⚛️","Learn React Fundamentals","Components, state, props, hooks (useState, useEffect). Build small CRUD apps with Axios HTTP calls."),
    ("03",ACCENT5,"☕","Java & Spring Boot Basics","OOP in Java, REST controllers, Maven builds. Create a simple Spring Boot API with H2 database."),
    ("04",ACCENT4,"🐳","Docker Essentials","Write a Dockerfile, run containers, understand Docker Compose for multi-service setups like BBHealthApp."),
    ("05",ACCENT3,"🔀","Git & Collaboration","Branch strategy, pull requests, merge conflicts. Git flow as used in Jenkins CI/CD pipeline."),
    ("06",ACCENT1,"🔐","Security Concepts","JWT tokens, password hashing with BCrypt, authentication vs authorization, and why CORS matters."),
]

positions_6 = [(0.3,1.45),(4.6,1.45),(8.9,1.45),(0.3,4.05),(4.6,4.05),(8.9,4.05)]
for (x,y),(num,col,ico,ttl,desc) in zip(positions_6, steps):
    box = sl.shapes.add_shape(1, Inches(x), Inches(y), Inches(4.0), Inches(2.35))
    box.fill.solid(); box.fill.fore_color.rgb = CARD
    box.line.color.rgb = BORDER; box.line.width = Pt(0.4)

    add_text(sl, num, x+2.9, y+0.05, 1.0, 0.55, size=32, bold=True, color=col, align=PP_ALIGN.RIGHT)
    add_text(sl, ico, x+0.12, y+0.1, 0.5, 0.45, size=18, color=WHITE)
    add_text(sl, ttl, x+0.15, y+0.6, 3.7, 0.35, size=12, bold=True, color=WHITE)
    add_text(sl, desc, x+0.15, y+1.0, 3.7, 1.2, size=9, color=MUTED, wrap=True)

slide_footer(sl, 7, TOTAL)

# ═══════════════════════════════════════════════
# SLIDE 8 – 8-WEEK CURRICULUM
# ═══════════════════════════════════════════════
sl = add_slide(); fill_bg(sl)
c1 = sl.shapes.add_shape(9, Inches(9), Inches(-1), Inches(6), Inches(6))
c1.fill.solid(); c1.fill.fore_color.rgb = RGBColor(0x00,0x22,0x30); c1.line.fill.background()

tag = sl.shapes.add_shape(9, Inches(5.0), Inches(0.18), Inches(3.3), Inches(0.35))
tag.fill.solid(); tag.fill.fore_color.rgb = RGBColor(0x00,0x22,0x30); tag.line.fill.background()
add_text(sl, "Course Curriculum", 5.05, 0.2, 3.2, 0.3, size=9, bold=True, color=ACCENT2, align=PP_ALIGN.CENTER)
add_text(sl, "8-Week Learning Path", 1, 0.6, 11.33, 0.6, size=26, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

timeline_data = [
    (ACCENT1, "Week 1–2", "Foundation & Setup",
     "System architecture deep-dive  ·  Docker Compose local setup  ·  Git workflow  ·  Reading ARCHITECTURE.md & PROJECT_DOCUMENTATION.md"),
    (ACCENT2, "Week 3–4", "Backend Deep Dive",
     "Spring Boot microservices  ·  JWT security implementation  ·  REST API design  ·  H2 → MySQL database  ·  Debugging ERROR_LOG issues"),
    (ACCENT5, "Week 5–6", "Frontend & Integration",
     "React components  ·  Material-UI  ·  RxJS state management  ·  Axios API integration  ·  Role-based dashboards  ·  End-to-end testing"),
    (ACCENT4, "Week 7–8", "Cloud & Production Deployment",
     "AWS EKS  ·  Kubernetes deployments  ·  Helm charts  ·  Jenkins pipeline  ·  ECR image push  ·  ALB Ingress  ·  Terraform IaC  ·  CloudWatch"),
]

y_start = 1.45
for i,(col,week,title,desc) in enumerate(timeline_data):
    y = y_start + i * 1.42

    # dot
    dot = sl.shapes.add_shape(9, Inches(0.6), Inches(y+0.28), Inches(0.22), Inches(0.22))
    dot.fill.solid(); dot.fill.fore_color.rgb = col; dot.line.fill.background()

    # connector line (not on last)
    if i < len(timeline_data)-1:
        conn = sl.shapes.add_shape(1, Inches(0.7), Inches(y+0.52), Inches(0.04), Inches(0.88))
        conn.fill.solid(); conn.fill.fore_color.rgb = BORDER; conn.line.fill.background()

    # content box
    cbox = sl.shapes.add_shape(1, Inches(1.1), Inches(y+0.05), Inches(11.6), Inches(1.2))
    cbox.fill.solid(); cbox.fill.fore_color.rgb = CARD
    cbox.line.color.rgb = col; cbox.line.width = Pt(0.5)

    lbar = sl.shapes.add_shape(1, Inches(1.1), Inches(y+0.05), Inches(0.06), Inches(1.2))
    lbar.fill.solid(); lbar.fill.fore_color.rgb = col; lbar.line.fill.background()

    add_text(sl, week,  1.25, y+0.08, 2, 0.28, size=9,  bold=True, color=col)
    add_text(sl, title, 1.25, y+0.38, 5, 0.32, size=13, bold=True, color=WHITE)
    add_text(sl, desc,  1.25, y+0.72, 11.3, 0.45, size=9, color=MUTED, wrap=True)

slide_footer(sl, 8, TOTAL)

# ═══════════════════════════════════════════════
# SLIDE 9 – FRESHER vs EXPERIENCED
# ═══════════════════════════════════════════════
sl = add_slide(); fill_bg(sl)
c1 = sl.shapes.add_shape(9, Inches(-1), Inches(-1), Inches(5), Inches(5))
c1.fill.solid(); c1.fill.fore_color.rgb = RGBColor(0x28,0x08,0x20); c1.line.fill.background()

tag = sl.shapes.add_shape(9, Inches(5.0), Inches(0.18), Inches(3.3), Inches(0.35))
tag.fill.solid(); tag.fill.fore_color.rgb = RGBColor(0x28,0x08,0x20); tag.line.fill.background()
add_text(sl, "Course Design", 5.05, 0.2, 3.2, 0.3, size=9, bold=True, color=ACCENT3, align=PP_ALIGN.CENTER)
add_text(sl, "Course Focus:  Fresher  vs  Experienced", 1, 0.62, 11.33, 0.6, size=26, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

# Fresher box
fb = sl.shapes.add_shape(1, Inches(0.4), Inches(1.45), Inches(6.0), Inches(5.65))
fb.fill.solid(); fb.fill.fore_color.rgb = CARD
fb.line.color.rgb = ACCENT1; fb.line.width = Pt(0.8)

fbar = sl.shapes.add_shape(1, Inches(0.4), Inches(1.45), Inches(6.0), Inches(0.06))
fbar.fill.solid(); fbar.fill.fore_color.rgb = ACCENT1; fbar.line.fill.background()

add_text(sl, "🌱", 0.55, 1.6, 0.6, 0.5, size=22)
add_text(sl, "FRESHER TRACK", 1.2, 1.62, 5, 0.22, size=8, bold=True, color=ACCENT1)
add_text(sl, "Guided Learning", 1.2, 1.85, 5, 0.32, size=14, bold=True, color=WHITE)

fresher_items = [
    ("📖","Structured modules with step-by-step labs"),
    ("🏗️","Architecture-first: understand before coding"),
    ("🧑‍🏫","Pair programming with mentors"),
    ("🐛","Guided debugging of ERROR_LOG issues"),
    ("📋","Pre-built tasks: add an API endpoint, fix a bug, write a test"),
    ("☁️","Assisted cloud deployment with Helm & EKS"),
    ("🏆","Portfolio project: a documented PR to BBHealthApp"),
]
for i,(ico,txt) in enumerate(fresher_items):
    y = 2.32 + i*0.48
    add_text(sl, ico, 0.6, y, 0.38, 0.38, size=13)
    add_text(sl, txt, 1.05, y+0.04, 5.1, 0.38, size=10, color=MUTED, wrap=True)

# Experienced box
eb = sl.shapes.add_shape(1, Inches(6.9), Inches(1.45), Inches(6.0), Inches(5.65))
eb.fill.solid(); eb.fill.fore_color.rgb = CARD
eb.line.color.rgb = ACCENT5; eb.line.width = Pt(0.8)

ebar = sl.shapes.add_shape(1, Inches(6.9), Inches(1.45), Inches(6.0), Inches(0.06))
ebar.fill.solid(); ebar.fill.fore_color.rgb = ACCENT5; ebar.line.fill.background()

add_text(sl, "🚀", 7.05, 1.6, 0.6, 0.5, size=22)
add_text(sl, "EXPERIENCED TRACK", 7.7, 1.62, 5, 0.22, size=8, bold=True, color=ACCENT5)
add_text(sl, "Deep-dive Engineering", 7.7, 1.85, 5, 0.32, size=14, bold=True, color=WHITE)

exp_items = [
    ("⚡","Self-paced with advanced design challenges"),
    ("🏛️","Propose and implement architectural improvements"),
    ("🔒","Harden security: CORS, refresh tokens, rate limiting"),
    ("📊","Add Prometheus/Grafana monitoring stack"),
    ("🗄️","Migrate H2 → PostgreSQL with Flyway migrations"),
    ("🧪","Write integration + end-to-end tests (JUnit, Cypress)"),
    ("🌐","Implement Future Improvements from project docs"),
]
for i,(ico,txt) in enumerate(exp_items):
    y = 2.32 + i*0.48
    add_text(sl, ico, 7.1, y, 0.38, 0.38, size=13)
    add_text(sl, txt, 7.55, y+0.04, 5.1, 0.38, size=10, color=MUTED, wrap=True)

slide_footer(sl, 9, TOTAL)

# ═══════════════════════════════════════════════
# SLIDE 10 – OUTCOMES / CTA
# ═══════════════════════════════════════════════
sl = add_slide(); fill_bg(sl)
c1 = sl.shapes.add_shape(9, Inches(8),  Inches(-2), Inches(7), Inches(7))
c1.fill.solid(); c1.fill.fore_color.rgb = RGBColor(0x0C,0x10,0x35); c1.line.fill.background()
c2 = sl.shapes.add_shape(9, Inches(-2), Inches(3),  Inches(6), Inches(6))
c2.fill.solid(); c2.fill.fore_color.rgb = RGBColor(0x00,0x25,0x20); c2.line.fill.background()

tag = sl.shapes.add_shape(9, Inches(5.1), Inches(0.18), Inches(3.1), Inches(0.35))
tag.fill.solid(); tag.fill.fore_color.rgb = RGBColor(0x00,0x25,0x20); tag.line.fill.background()
add_text(sl, "Outcomes", 5.15, 0.2, 3.0, 0.3, size=9, bold=True, color=ACCENT5, align=PP_ALIGN.CENTER)

add_text(sl, "What You'll Walk Away With", 1, 0.62, 11.33, 0.65, size=26, bold=True, color=WHITE, align=PP_ALIGN.CENTER)
add_text(sl, "After completing the FDE program, every participant — fresher or experienced — walks away with measurable, demonstrable skills.",
         1.5, 1.28, 10.33, 0.45, size=12, color=MUTED, align=PP_ALIGN.CENTER)

outcomes = [
    (ACCENT1,"🏗️","Production Codebase","Merged PRs on a real microservices project you can show in interviews."),
    (ACCENT2,"☁️","Cloud Deployment","A live app running on AWS EKS with CI/CD — not just a tutorial screenshot."),
    (ACCENT5,"🔐","Security Skills","JWT, BCrypt, RBAC — implemented in real security, not just theory."),
    (ACCENT4,"📋","Engineering Habits","Documentation, incident logs, Git discipline — skills that make you stand out."),
    (ACCENT3,"🤝","Team Skills","PR reviews, Git workflow, Jenkins pipelines — work like a professional team."),
]
for i,(col,ico,ttl,desc) in enumerate(outcomes):
    x = 0.4 + i*2.53
    box = sl.shapes.add_shape(1, Inches(x), Inches(1.95), Inches(2.28), Inches(3.8))
    box.fill.solid(); box.fill.fore_color.rgb = CARD
    box.line.color.rgb = BORDER; box.line.width = Pt(0.4)

    topbar = sl.shapes.add_shape(1, Inches(x), Inches(1.95), Inches(2.28), Inches(0.06))
    topbar.fill.solid(); topbar.fill.fore_color.rgb = col; topbar.line.fill.background()

    add_text(sl, ico,  x+0.1, 2.08, 2.0, 0.5, size=22)
    add_text(sl, ttl,  x+0.12, 2.65, 2.05, 0.35, size=11, bold=True, color=col)
    add_text(sl, desc, x+0.12, 3.08, 2.05, 2.5, size=9,  color=MUTED, wrap=True)

# CTA banner
cta = sl.shapes.add_shape(1, Inches(2.0), Inches(6.0), Inches(9.33), Inches(0.95))
cta.fill.solid(); cta.fill.fore_color.rgb = ACCENT1; cta.line.fill.background()
add_text(sl, "🚀  Start Your FDE Journey Today  —  Build Real. Deploy Real. Grow Real.", 2.1, 6.12, 9.1, 0.7,
         size=15, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

slide_footer(sl, 10, TOTAL)

# ── Save ─────────────────────────────────────────────────────────
out = "/Users/ishika/CascadeProjects/windsurf-project-3/docs/FDE_Presentation.pptx"
prs.save(out)
print(f"✅  Saved: {out}")
