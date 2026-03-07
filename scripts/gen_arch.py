import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

fig, ax = plt.subplots(figsize=(16, 11))
fig.patch.set_facecolor('#1a1b26')
ax.set_facecolor('#1a1b26')
ax.set_xlim(0, 16); ax.set_ylim(0, 11)

C_BOX='#24283b'; C_DARK='#16161e'; C_MAIN='#1e2030'; C_TXT='#c0caf5'
C_ARR='#7aa2f7'; C_EDGE_MAIN='#565f89'; C_SUB='#7a7a9a'
C_NGX    ='#2ac3de'; E_NGX    ='#1a5a6e'
C_GATEWAY='#bb9af7'; E_GATEWAY='#3d3060'
C_NETWORK='#73daca'; E_NETWORK='#204840'
C_MEDIA  ='#ff9e64'; E_MEDIA  ='#5a3420'
C_MON    ='#e0af68'; E_MON    ='#5a4020'
C_SMART  ='#9ece6a'; E_SMART  ='#2a4a20'
C_GAME   ='#f7768e'; E_GAME   ='#5a2030'
C_FILES  ='#7aa2f7'; E_FILES  ='#203060'
C_WEB    ='#7dcfff'; E_WEB    ='#203850'

def box(x,y,w,h,fc=C_BOX,ec=C_EDGE_MAIN,lw=1.3,pad=0.08,zorder=2):
    ax.add_patch(FancyBboxPatch((x,y),w,h,boxstyle=f'round,pad={pad}',
                                facecolor=fc,edgecolor=ec,linewidth=lw,zorder=zorder))

def label(x,y,txt,color=C_TXT,fs=8.5,bold=False,ha='center',va='center'):
    ax.text(x,y,txt,color=color,fontsize=fs,ha=ha,va=va,
            fontweight='bold' if bold else 'normal',zorder=5)

def items(cx,first_y,entries,fs=10.5,dy=0.40):
    for i,e in enumerate(entries): label(cx,first_y-i*dy,e,fs=fs)

def varr(x,y0,y1,col=C_ARR):
    ax.annotate('',xy=(x,y1),xytext=(x,y0),
                arrowprops=dict(arrowstyle='->',color=col,lw=1.3,shrinkA=5,shrinkB=5))

def darr(x0,y0,x1,y1,col=C_ARR,rad=0.0,lw=1.1):
    ax.annotate('',xy=(x1,y1),xytext=(x0,y0),
                arrowprops=dict(arrowstyle='->',color=col,lw=lw,shrinkA=5,shrinkB=8,
                               connectionstyle=f'arc3,rad={rad}'))

def bh(n): return 0.56+n*0.40

# Service lists
MED_LIST  = ['Plex  ·  streaming','Overseerr  ·  requests',
             'Sonarr  ·  TV shows','Radarr  ·  movies',
             'Tautulli  ·  analytics','Recyclarr  ·  quality profiles']
VPN_LIST  = ['Gluetun  ·  VPN tunnel','qBittorrent  ·  downloads',
             'FlareSolverr  ·  Cloudflare bypass','Prowlarr  ·  indexers']
MON_LIST  = ['Homepage  ·  index','Grafana  ·  dashboards',
             'Dozzle  ·  log viewer','Prometheus  ·  app metrics',
             'Node Exporter  ·  host metrics','Uptime Kuma  ·  app uptime']
MAINT_LIST= ['Watchtower  ·  auto-updates','Autoheal  ·  health recovery']
HS_ITEMS  = ['VPN coordinator']
GS_LIST   = ['Pterodactyl  ·  panel','Minecraft  ·  game',
             'Valheim  ·  game','Factorio  ·  game','Satisfactory  ·  game']
SMART_LIST= ['Home Assistant  ·  device orchestration',
             'Mosquitto  ·  MQTT','Govee2MQTT  ·  IoT bridge']
WEB_LIST  = ['martinhodde.com  ·  personal site',
             'info.monkeyhub.net  ·  overview',
             'play.monkeyhub.net  ·  game status',
             'auth.monkeyhub.net  ·  auth proxy']
FIL_LIST  = ['Nextcloud  ·  file sync','Immich  ·  photo sync',
             'Duplicati  ·  backups']
NET_LIST  = ['AdGuard Home  ·  DNS, ad-block',
             'Tailscale Router  ·  subnet access',
             'ProtonVPN  ·  WireGuard VPN']

# Layout
MAIN_X=0.12; MAIN_W=15.76
COL_W=3.40; COL_GAP=0.45
MARGIN=(MAIN_W-4*COL_W-3*COL_GAP)/2
MED_X=MAIN_X+MARGIN; MON_X=MED_X+COL_W+COL_GAP
SH_X=MON_X+COL_W+COL_GAP; FIL_X=SH_X+COL_W+COL_GAP
MED_CX=MED_X+COL_W/2; MON_CX=MON_X+COL_W/2
SH_CX=SH_X+COL_W/2;   FIL_CX=FIL_X+COL_W/2
NGX_W=4*COL_W+3*COL_GAP; NGX_X=MED_X

BOX_W = NGX_W * 0.65
BOX_X = NGX_X + (NGX_W - BOX_W) / 2
BOX_CX = BOX_X + BOX_W / 2

GAP = 0.35  # inter-box gap within columns

K_media=(0.24+0.44+(len(MED_LIST)-1)*0.40+0.20
        +GAP+0.24+0.44+(len(VPN_LIST)-1)*0.40+0.20
        +GAP+0.56+0.18)

# Heights
HS_H=bh(len(HS_ITEMS)); MON_H2=bh(len(MON_LIST)); MAINT_H=bh(len(MAINT_LIST))
AUTH_H=bh(1); GS_H=bh(len(GS_LIST)); SMART_H=bh(len(SMART_LIST))
WEB_H=bh(len(WEB_LIST)); FIL_H=bh(len(FIL_LIST)); NET_H=bh(len(NET_LIST))

# Vertical layout
INET_H=0.70
INET_Y=10.20; INET_CY=INET_Y+INET_H/2
HOME_TOP=INET_Y-0.50
NGX_H_inner=0.72
NGX_inner_TOP=HOME_TOP-0.70
NGX_inner_Y=NGX_inner_TOP-NGX_H_inner
NGX_inner_CY=(NGX_inner_TOP+NGX_inner_Y)/2
COL_TOP=NGX_inner_Y-0.45

MED_OUTER_Y = COL_TOP - K_media
COL2_BOT = COL_TOP - HS_H - GAP - MON_H2 - GAP - MAINT_H
COL3_BOT = COL_TOP - AUTH_H - GAP - GS_H - GAP - SMART_H
COL4_BOT = COL_TOP - WEB_H - GAP - FIL_H - GAP - NET_H

MAIN_Y = min(MED_OUTER_Y, COL2_BOT, COL3_BOT, COL4_BOT) - 0.35
MAIN_H = HOME_TOP - MAIN_Y

# Internet (outside homelab)
box(BOX_X,INET_Y,BOX_W,INET_H,fc=C_MAIN,ec=E_GATEWAY,lw=1.5)
label(BOX_CX,INET_CY,'Internet',color=C_GATEWAY,fs=12,bold=True)

# Arrow: Internet → Nginx, shifted left to clear homelab title but not too far
varr(BOX_X+2.2, INET_Y, NGX_inner_TOP)

# Homelab outer box
box(MAIN_X,MAIN_Y,MAIN_W,MAIN_H,fc=C_MAIN,ec=C_EDGE_MAIN,lw=1.8,pad=0.12,zorder=1)
label(MAIN_X+MAIN_W/2,HOME_TOP-0.24,
      'Homelab  (Ubuntu · Docker)',color=C_EDGE_MAIN,fs=11.5,bold=True)

# Nginx
box(BOX_X,NGX_inner_Y,BOX_W,NGX_H_inner,fc='#1a2030',ec=E_NGX,lw=1.8)
label(BOX_CX,NGX_inner_CY+0.14,'Nginx + Certbot',color=C_NGX,fs=12,bold=True)
label(BOX_CX,NGX_inner_CY-0.14,'reverse proxy',color=C_SUB,fs=9.5)

# Nginx arrows
# → Headscale (col 2 top)
varr(MON_CX, NGX_inner_Y, COL_TOP, col=C_NGX)
# → Authentik Outpost (col 3 top)
varr(SH_CX, NGX_inner_Y, COL_TOP, col=C_NGX)
# → Websites (col 4 top): right-angle from Nginx right side
ax.plot([BOX_X+BOX_W+0.08, FIL_CX], [NGX_inner_CY, NGX_inner_CY],
        color=C_NGX, lw=1.3, zorder=4)
ax.annotate('', xy=(FIL_CX, COL_TOP), xytext=(FIL_CX, NGX_inner_CY),
            arrowprops=dict(arrowstyle='->', color=C_NGX, lw=1.3,
                           shrinkA=0, shrinkB=5))
# → Media (col 1 top): right-angle from Nginx left side
ax.plot([BOX_X-0.08, MED_CX], [NGX_inner_CY, NGX_inner_CY],
        color=C_NGX, lw=1.3, zorder=4)
ax.annotate('', xy=(MED_CX, COL_TOP), xytext=(MED_CX, NGX_inner_CY),
            arrowprops=dict(arrowstyle='->', color=C_NGX, lw=1.3,
                           shrinkA=0, shrinkB=5))

# Col 1: Media
MED_HEAD_Y=COL_TOP-0.24; MED_FIRST_Y=MED_HEAD_Y-0.44
MED_BOT=MED_FIRST_Y-(len(MED_LIST)-1)*0.40-0.20
VPN_TOP=MED_BOT-GAP; VPN_HEAD_Y=VPN_TOP-0.24
VPN_FIRST_Y=VPN_HEAD_Y-0.44
VPN_BOT=VPN_FIRST_Y-(len(VPN_LIST)-1)*0.40-0.20
STO_TOP=VPN_BOT-GAP; STO_H=0.56; STO_BOT=STO_TOP-STO_H

box(MED_X,MED_OUTER_Y,COL_W,COL_TOP-MED_OUTER_Y,ec=E_MEDIA,lw=1.4)
label(MED_CX,MED_HEAD_Y,'Media',color=C_MEDIA,fs=12,bold=True)
items(MED_CX,MED_FIRST_Y,MED_LIST)
box(MED_X+0.12,VPN_BOT,COL_W-0.24,VPN_TOP-VPN_BOT,fc=C_DARK,ec=C_MEDIA,pad=0.06)
label(MED_CX,VPN_HEAD_Y,'Downloads (VPN)',color=C_MEDIA,fs=11.5,bold=True)
items(MED_CX,VPN_FIRST_Y,VPN_LIST)
box(MED_X+0.12,STO_BOT,COL_W-0.24,STO_H,fc=C_DARK,ec=E_MEDIA,pad=0.06)
label(MED_CX,STO_BOT+STO_H/2,'80 TB RAID5 Array',fs=11.0)

# Col 2: Headscale + Monitoring + Maintenance
HS_BOX_Y=COL_TOP-HS_H; HS_CY=COL_TOP-HS_H/2
box(MON_X,HS_BOX_Y,COL_W,HS_H,fc='#1a2030',ec=E_NETWORK,lw=1.4)
label(MON_CX,COL_TOP-0.24,'Headscale',color=C_NETWORK,fs=12,bold=True)
items(MON_CX,COL_TOP-0.24-0.44,HS_ITEMS)

MON_TOP=HS_BOX_Y-GAP; MON_Y=MON_TOP-MON_H2
box(MON_X,MON_Y,COL_W,MON_H2,ec=E_MON,lw=1.4)
label(MON_CX,MON_TOP-0.24,'Monitoring',color=C_MON,fs=12,bold=True)
items(MON_CX,MON_TOP-0.24-0.44,MON_LIST)

MAINT_TOP=MON_Y-GAP; MAINT_Y=MAINT_TOP-MAINT_H
box(MON_X,MAINT_Y,COL_W,MAINT_H,ec=E_MON,lw=1.4)
label(MON_CX,MAINT_TOP-0.24,'Maintenance',color=C_MON,fs=12,bold=True)
items(MON_CX,MAINT_TOP-0.24-0.44,MAINT_LIST)

# Col 3: Authentik Outpost + Game Servers + Smart Home
AUTH_BOX_Y=COL_TOP-AUTH_H; AUTH_CY=COL_TOP-AUTH_H/2
box(SH_X,AUTH_BOX_Y,COL_W,AUTH_H,fc='#1a2030',ec=E_GATEWAY,lw=1.4)
label(SH_CX,AUTH_CY+0.14,'Authentik Outpost',color=C_GATEWAY,fs=12,bold=True)
label(SH_CX,AUTH_CY-0.14,'access control',color=C_SUB,fs=9.5)

GS_TOP=AUTH_BOX_Y-GAP; GS_BOX_Y=GS_TOP-GS_H
varr(SH_CX, AUTH_BOX_Y, GS_TOP, col=C_GATEWAY)
box(SH_X,GS_BOX_Y,COL_W,GS_H,ec=E_GAME,lw=1.4)
label(SH_CX,GS_TOP-0.24,'Game Servers',color=C_GAME,fs=12,bold=True)
items(SH_CX,GS_TOP-0.24-0.44,GS_LIST)

SMART_TOP=GS_BOX_Y-GAP; SMART_BOX_Y=SMART_TOP-SMART_H
box(SH_X,SMART_BOX_Y,COL_W,SMART_H,ec=E_SMART,lw=1.4)
label(SH_CX,SMART_TOP-0.24,'Smart Home',color=C_SMART,fs=12,bold=True)
items(SH_CX,SMART_TOP-0.24-0.44,SMART_LIST)

# Col 4: Websites + Files & Backup + Networking
WEB_BOX_Y=COL_TOP-WEB_H
box(FIL_X,WEB_BOX_Y,COL_W,WEB_H,ec=E_WEB,lw=1.4)
label(FIL_CX,COL_TOP-0.24,'Websites',color=C_WEB,fs=12,bold=True)
items(FIL_CX,COL_TOP-0.24-0.44,WEB_LIST)

FIL_TOP=WEB_BOX_Y-GAP; FIL_BOX_Y=FIL_TOP-FIL_H
box(FIL_X,FIL_BOX_Y,COL_W,FIL_H,ec=E_FILES,lw=1.4)
label(FIL_CX,FIL_TOP-0.24,'Files & Backup',color=C_FILES,fs=12,bold=True)
items(FIL_CX,FIL_TOP-0.24-0.44,FIL_LIST)

NET_TOP=FIL_BOX_Y-GAP; NET_BOX_Y=NET_TOP-NET_H
box(FIL_X,NET_BOX_Y,COL_W,NET_H,ec=E_NETWORK,lw=1.4)
label(FIL_CX,NET_TOP-0.24,'Networking',color=C_NETWORK,fs=12,bold=True)
items(FIL_CX,NET_TOP-0.24-0.44,NET_LIST)

# Plot
ax.set_ylim(MAIN_Y-0.15, INET_Y+INET_H+0.20)
ax.axis('off')
plt.tight_layout(pad=0)
plt.savefig('/home/mhodde/martinhodde.com/homelab/architecture.png',
            dpi=150,bbox_inches='tight',facecolor='#1a1b26')
print(f"Done. COL_TOP={COL_TOP:.2f} MED_OUTER_Y={MED_OUTER_Y:.2f}")
print(f"  COL2_BOT={COL2_BOT:.2f} COL3_BOT={COL3_BOT:.2f} COL4_BOT={COL4_BOT:.2f}")
print(f"  MAIN_Y={MAIN_Y:.2f}")
