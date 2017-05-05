
"""
from numpy import sqrt, pi, exp, linspace, loadtxt
from lmfit import  Model
import matplotlib.pyplot as plt

data = loadtxt('model1d_gauss.dat')
x = data[:, 0]
y = data[:, 1]

def gaussian(x, amp, cen, wid):
    "1-d gaussian: gaussian(x, amp, cen, wid)"
    return (amp/(sqrt(2*pi)*wid)) * exp(-(x-cen)**2 /(2*wid**2))

gmodel = Model(gaussian)
result = gmodel.fit(y, x=x, amp=5, cen=5, wid=1)

print(result.fit_report())

plt.plot(x, y,         'bo')
plt.plot(x, result.init_fit, 'k--')
plt.plot(x, result.best_fit, 'r-')
plt.show()
#<end examples/doc_model1.py>

"""
def zoom_factory(ax,base_scale = 2.):
    def zoom_fun(event):
        # get the current x and y limits
        cur_xlim = ax.get_xlim()
        cur_ylim = ax.get_ylim()
        # set the range
        cur_xrange = (cur_xlim[1] - cur_xlim[0])*.5
        cur_yrange = (cur_ylim[1] - cur_ylim[0])*.5
        xdata = event.xdata # get event x location
        ydata = event.ydata # get event y location
        if event.button == 'up':
            # deal with zoom in
            scale_factor = 1/base_scale
        elif event.button == 'down':
            # deal with zoom out
            scale_factor = base_scale
        else:
            # deal with something that should never happen
            scale_factor = 1
            print event.button
        # set new limits
        ax.set_xlim([xdata - cur_xrange*scale_factor,
                     xdata + cur_xrange*scale_factor])
        ax.set_ylim([ydata - cur_yrange*scale_factor,
                     ydata + cur_yrange*scale_factor])
        ax.figure.canvas.draw() # force re-draw

    fig = ax.get_figure() # get the figure of interest
    # attach the call back
    fig.canvas.mpl_connect('scroll_event',zoom_fun)

    #return the function
    return zoom_fun


from matplotlib import pyplot as plt
class ScatterBuilder:
    def __init__(self, scatter):
        self.scatter = scatter
        self.xs = list(scatter.get_xdata())
        self.ys = list(scatter.get_ydata())
        self.cid = scatter.figure.canvas.mpl_connect('button_press_event', self)

    def __call__(self, event):
        print('click', event)
        if event.inaxes!=self.scatter.axes: return
        self.xs.append(event.xdata)
        self.ys.append(event.ydata)
        self.scatter.set_data(self.xs, self.ys)
	self.scatter.set_marker('o')
	self.scatter.set_linestyle('None')
        self.scatter.figure.canvas.draw()


fig = plt.figure()
ax = fig.add_subplot(111)
ax.set_title('Click to add points')
scatter, = ax.plot([],[])  # empty line
f = zoom_factory(ax,base_scale = 1.5)
Scatterbuilder = ScatterBuilder(scatter)

plt.show()
