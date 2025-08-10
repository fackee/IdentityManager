export class DocumentItem {
  id: string
  name: string
  type: string
  number: string
  expiryDate: string
  imageUrl: Resource
  createTime: Date
  updateTime: Date

  constructor(
    id: string = '',
    name: string = '',
    type: string = '',
    number: string = '',
    expiryDate: string = '',
    imageUrl: Resource = $r('app.media.background'),
    createTime: Date = new Date(),
    updateTime: Date = new Date()
  ) {
    this.id = id
    this.name = name
    this.type = type
    this.number = number
    this.expiryDate = expiryDate
    this.imageUrl = imageUrl
    this.createTime = createTime
    this.updateTime = updateTime
  }
} 